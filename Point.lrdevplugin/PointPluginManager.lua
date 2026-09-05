
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrPrefs = import 'LrPrefs'

local prefs = LrPrefs.prefsForPlugin()

local PluginManager = {}

function PluginManager.sectionsForTopOfDialog( f, propertyTable )
    -- Initialize property table with current prefs
    propertyTable.apiUrl = prefs.apiUrl or ""
    propertyTable.apiToken = prefs.apiToken or ""
    
    -- When properties change, save to prefs
    propertyTable:addObserver('apiUrl', function(propertyTable, key, value)
        prefs.apiUrl = value
    end)
    
    propertyTable:addObserver('apiToken', function(propertyTable, key, value)
        prefs.apiToken = value
    end)

    return {
        {
            title = "Point API Settings",
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
        }
    }
end

return PluginManager
