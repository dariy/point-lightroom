local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrFileUtils = import 'LrFileUtils'

local PointAPI = require 'PointAPI'

local exportServiceProvider = {}

exportServiceProvider.exportPresetFields = {
    { key = 'apiUrl', default = '' },
    { key = 'apiToken', default = '' },
}

function exportServiceProvider.sectionsForTopOfDialog(f, propertyTable)
    return {
        {
            title = 'Point API Configuration',
            synopsis = function(props)
                if props.apiUrl and props.apiUrl ~= "" then
                    return props.apiUrl
                else
                    return "Not configured"
                end
            end,
            f:row {
                f:static_text {
                    title = 'API URL:',
                    alignment = 'right',
                    width = LrView.share 'label_width',
                },
                f:edit_field {
                    value = LrBinding.bind('apiUrl'),
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
                    value = LrBinding.bind('apiToken'),
                    width_in_chars = 30,
                    fill_horizontal = 1,
                },
            },
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

    if not apiUrl or apiUrl == "" or not apiToken or apiToken == "" then
        LrDialogs.message("Export Error", "Please configure the Point API URL and Token in the export dialog.", "critical")
        progressScope:done()
        return
    end

    local errors = {}

    for i, rendition in exportContext:renditions { stopIfCanceled = true } do
        progressScope:setPortionComplete(i - 1, nPhotos)
        
        local success, pathOrMessage = rendition:waitForRender()

        if progressScope:isCanceled() then
            break
        end

        if success then
            local fileName = LrFileUtils.leafName(pathOrMessage)
            progressScope:setCaption("Uploading " .. fileName .. "...")
            
            local uploadSuccess, uploadMessage = PointAPI.uploadMedia(apiUrl, apiToken, pathOrMessage, fileName)
            
            if not uploadSuccess then
                table.insert(errors, "Failed to upload " .. fileName .. ": " .. uploadMessage)
            end
        else
            table.insert(errors, "Failed to render a photo: " .. (pathOrMessage or "Unknown error"))
        end
    end

    progressScope:done()

    if #errors > 0 then
        LrDialogs.message("Export Completed with Errors", table.concat(errors, "\n"), "warning")
    end
end

return exportServiceProvider
