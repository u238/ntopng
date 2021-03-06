--
-- (C) 2019-20 - ntop.org
--

-- ##############################################

local alert_keys = require "alert_keys"
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path

local json = require("dkjson")
local alert_creators = require "alert_creators"
local format_utils = require "format_utils"

-- Import the classes library.
local classes = require "classes"
-- Make sure to import the Superclass!
local alert = require "alert"

-- ##############################################

local alert_tcp_syn_flood = classes.class(alert)

-- ##############################################

alert_tcp_syn_flood.meta = {
  alert_key = alert_keys.ntopng.alert_tcp_syn_flood,
  i18n_title = "alerts_dashboard.tcp_syn_flood",
  icon = "fas fa-life-ring",
}

-- ##############################################

-- @brief Prepare an alert table used to generate the alert
-- @param one_param The first alert param
-- @param another_param The second alert param
-- @return A table with the alert built
function alert_tcp_syn_flood:init(one_param, another_param)
   -- Call the paren constructor
   self.super:init()

   self.alert_type_params = alert_creators.createThresholdCross(metric, value, operator, threshold)
end

-- #######################################################

-- @brief Format an alert into a human-readable string
-- @param ifid The integer interface id of the generated alert
-- @param alert The alert description table, including alert data such as the generating entity, timestamp, granularity, type
-- @param alert_type_params Table `alert_type_params` as built in the `:init` method
-- @return A human-readable string
function alert_tcp_syn_flood.format(ifid, alert, alert_type_params)
  local alert_consts = require "alert_consts"
  local entity = alert_consts.formatAlertEntity(ifid, alert_consts.alertEntityRaw(alert["alert_entity"]), alert["alert_entity_val"])
  
  if(alert.alert_subtype == "syn_flood_attacker") then
    return i18n("alert_messages.syn_flood_attacker", {
      entity = firstToUpper(entity),
      host_category = format_utils.formatAddressCategory((json.decode(alert.alert_json)).alert_generation.host_info),
      value = string.format("%u", math.ceil(alert_type_params.value)),
      threshold = alert_type_params.threshold,
    })
  else
    return i18n("alert_messages.syn_flood_victim", {
      entity = firstToUpper(entity),
      host_category = format_utils.formatAddressCategory((json.decode(alert.alert_json)).alert_generation.host_info),
      value = string.format("%u", math.ceil(alert_type_params.value)),
      threshold = alert_type_params.threshold,
    })
  end
end

-- #######################################################

return alert_tcp_syn_flood
