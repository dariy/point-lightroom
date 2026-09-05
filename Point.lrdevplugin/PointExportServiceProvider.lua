
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrPathUtils = import 'LrPathUtils'
local LrHttp = import 'LrHttp'

local PointAPI = require 'PointAPI'

local exportServiceProvider = {}

exportServiceProvider.supportsIncrementalPublish = true
exportServiceProvider.titleForPublishedCollection = "Post"
exportServiceProvider.titleForPublishedCollection_standalone = "Post"
exportServiceProvider.titleForPublishedSmartCollection = "Smart Post"
exportServiceProvider.titleForPublishedSmartCollection_standalone = "Smart Post"

exportServiceProvider.exportPresetFields = {
    { key = 'apiUrl', default = '' },
    { key = 'apiToken', default = '' },
}

function exportServiceProvider.sectionsForTopOfDialog(f, propertyTable)
    return {
        {
            title = 'Point API Configuration',
            f:column {
                spacing = f:control_spacing(),
                f:row {
                    f:static_text {
                        title = 'API URL:',
                        alignment = 'right',
                        width = LrView.share 'label_width',
                    },
                    f:edit_field {
                        value = LrView.bind('apiUrl'),
                        width_in_chars = 30,
                        fill_horizontal = 1,
                    },
                },
                f:row {
                    f:static_text {
                        title = 'API Token:',
                        alignment = 'right',
                        width = LrView.share 'label_width',
                    },
                    f:password_field {
                        value = LrView.bind('apiToken'),
                        width_in_chars = 30,
                        fill_horizontal = 1,
                    },
                },
            }
        },
    }
end

function exportServiceProvider.processRenderedPhotos(functionContext, exportContext)
    local exportSession = exportContext.exportSession
    local exportSettings = exportContext.propertyTable
    local nPhotos = exportSession:countRenditions()

    local progressScope = exportContext:configureProgress({
        title = nPhotos > 1 and ("Exporting " .. nPhotos .. " photos to Point") or "Exporting photo to Point",
    })

    local apiUrl = exportSettings.apiUrl
    local apiToken = exportSettings.apiToken

    -- Fallback to global plugin preferences
    if not apiUrl or apiUrl == "" then
        local LrPrefs = import 'LrPrefs'
        local prefs = LrPrefs.prefsForPlugin()
        apiUrl = prefs.apiUrl
        apiToken = prefs.apiToken
    end

    if not apiUrl or apiUrl == "" or not apiToken or apiToken == "" then
        LrDialogs.message("Export Error", "Please configure the Point API URL and Token in the Export/Publish settings.", "critical")
        progressScope:done()
        return
    end

    local errors = {}
    local uploadedImages = {}

    for i, rendition in exportContext:renditions { stopIfCanceled = true } do
        progressScope:setPortionComplete(i - 1, nPhotos)

        local success, pathOrMessage = rendition:waitForRender()

        if progressScope:isCanceled() then
            break
        end

        if success then
            local fileName = LrPathUtils.leafName(pathOrMessage)
            progressScope:setCaption("Uploading " .. fileName .. "...")

            local uploadSuccess, uploadMessage = PointAPI.uploadMedia(apiUrl, apiToken, pathOrMessage, fileName)

            if not uploadSuccess then
                table.insert(errors, "Failed to upload " .. fileName .. ": " .. uploadMessage)
            else
                local mediaPath = string.match(uploadMessage, '"path":%s*"([^"]+)"')
                if mediaPath then
                    table.insert(uploadedImages, mediaPath)

                    if exportSettings.LR_exportServiceProviderType == 'publish' then
                        local baseUrl = apiUrl
                        baseUrl = string.gsub(baseUrl, "/api/media/upload/?$", "")
                        baseUrl = string.gsub(baseUrl, "/api/posts/?$", "")
                        if string.sub(baseUrl, -1) == "/" then
                            baseUrl = string.sub(baseUrl, 1, -2)
                        end

                        -- Check if mediaPath starts with slash just in case
                        local fullMediaUrl = baseUrl .. (string.sub(mediaPath, 1, 1) == "/" and "" or "/") .. mediaPath

                        rendition:recordPublishedPhotoId(mediaPath)
                        rendition:recordPublishedPhotoUrl(fullMediaUrl)
                    end
                else
                    table.insert(errors, "Failed to parse upload response for " .. fileName)
                end
            end
        else
            table.insert(errors, "Failed to render a photo: " .. (pathOrMessage or "Unknown error"))
        end
    end

    if #uploadedImages > 0 then
        progressScope:setCaption("Creating draft post...")
        local contentLines = {}
        for _, path in ipairs(uploadedImages) do
            table.insert(contentLines, path)
        end
        local postContent = table.concat(contentLines, "\n\n")

        local postSuccess, postMessage = PointAPI.createPost(apiUrl, apiToken, postContent)
        if postSuccess then
            local postId = string.match(postMessage, '"id":%s*(%d+)')
            if postId then
                local baseUrl = apiUrl
                baseUrl = string.gsub(baseUrl, "/api/media/upload/?$", "")
                baseUrl = string.gsub(baseUrl, "/api/posts/?$", "")
                if string.sub(baseUrl, -1) == "/" then
                    baseUrl = string.sub(baseUrl, 1, -2)
                end

                local editUrl = baseUrl .. "/light/posts/" .. postId .. "/edit"
                LrHttp.openUrlInBrowser(editUrl)
            else
                table.insert(errors, "Failed to parse create post response")
            end
        else
            table.insert(errors, "Failed to create draft post: " .. postMessage)
        end
    end

    progressScope:done()

    if #errors > 0 then
        LrDialogs.message("Export Completed with Errors", table.concat(errors, "\n"), "warning")
    end
end

function exportServiceProvider.deletePhotosFromPublishedCollection(publishSettings, arrayOfPhotoIds, deletedCallback, localCollectionId)
    -- Simply acknowledge the deletion so Lightroom clears them from the "Deleted Photos to Remove" queue.
    for i, photoId in ipairs(arrayOfPhotoIds) do
        deletedCallback(photoId)
    end
end

return exportServiceProvider
