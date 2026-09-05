local LrHttp = import 'LrHttp'

local PointAPI = {}

function PointAPI.uploadMedia(apiUrl, apiToken, filePath, fileName)
    if not apiUrl or apiUrl == "" then
        return false, "API URL is missing."
    end
    if not apiToken or apiToken == "" then
        return false, "API Token is missing."
    end

    local endpoint = apiUrl
    -- Ensure endpoint ends with /api/media/upload
    if not string.match(endpoint, "/api/media/upload/?$") then
        if string.sub(endpoint, -1) == "/" then
            endpoint = endpoint .. "api/media/upload"
        else
            endpoint = endpoint .. "/api/media/upload"
        end
    end

    local headers = {
        { field = 'Authorization', value = 'Bearer ' .. apiToken }
    }

    local mimeChunks = {
        { name = 'file', filePath = filePath, fileName = fileName, contentType = 'image/jpeg' }
    }

    local result, responseHeaders, response = LrHttp.postMultipart(endpoint, mimeChunks, headers)

    if result then
        -- result is the body of the HTTP response
        return true, result
    else
        return false, "Failed to connect to Point API or upload failed."
    end
end

function PointAPI.createPost(apiUrl, apiToken, content)
    if not apiUrl or apiUrl == "" then
        return false, "API URL is missing."
    end
    if not apiToken or apiToken == "" then
        return false, "API Token is missing."
    end

    local endpoint = apiUrl
    if not string.match(endpoint, "/api/posts/?$") then
        if string.sub(endpoint, -1) == "/" then
            endpoint = endpoint .. "api/posts"
        else
            endpoint = endpoint .. "/api/posts"
        end
    end

    local headers = {
        { field = 'Authorization', value = 'Bearer ' .. apiToken },
        { field = 'Content-Type', value = 'application/json' }
    }

    local safeContent = string.gsub(content, '\\', '\\\\')
    safeContent = string.gsub(safeContent, '"', '\\"')
    safeContent = string.gsub(safeContent, '\n', '\\n')
    safeContent = string.gsub(safeContent, '\r', '\\r')
    safeContent = string.gsub(safeContent, '\t', '\\t')

    local payload = '{"status":"draft","content":"' .. safeContent .. '"}'

    local result, responseHeaders, response = LrHttp.post(endpoint, payload, headers)

    if result then
        return true, result
    else
        return false, "Failed to connect to Point API or create post failed."
    end
end

return PointAPI
