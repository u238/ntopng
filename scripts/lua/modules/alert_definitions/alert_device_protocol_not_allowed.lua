--
-- (C) 2019-20 - ntop.org
--

-- ##############################################

local alert_keys = require "alert_keys"
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path

local status_keys = require "flow_keys"
-- Import the classes library.
local classes = require "classes"
-- Make sure to import the Superclass!
local alert = require "alert"

-- ##############################################

local alert_device_protocol_not_allowed = classes.class(alert)

-- ##############################################

alert_device_protocol_not_allowed.meta = {
   status_key = status_keys.ntopng.status_device_protocol_not_allowed,
   alert_key = alert_keys.ntopng.alert_device_protocol_not_allowed,
   i18n_title = "alerts_dashboard.suspicious_device_protocol",
   icon = "fas fa-exclamation",
}

-- ##############################################

-- @brief Prepare an alert table used to generate the alert
-- @param alert_severity A severity as defined in `alert_severities`
-- @param cli_devtype A string with the device type of the client
-- @param srv_devtype A string with the device type of the server
-- @param devproto_forbidden_peer A string with the forbidden peer, one of 'cli' or 'srv'
-- @param devproto_forbidden_id The nDPI ID of the forbidden application protocol
-- @return A table with the alert built
function alert_device_protocol_not_allowed:init(cli_devtype, srv_devtype, devproto_forbidden_peer, devproto_forbidden_id)
   -- Call the parent constructor
   self.super:init()

   self.alert_type_params = {
    ["cli.devtype"] = cli_devtype,
	 ["srv.devtype"] = srv_devtype,
	 devproto_forbidden_peer = devproto_forbidden_peer,
    devproto_forbidden_id = devproto_forbidden_id
   }
end

-- #######################################################

-- @brief Format an alert into a human-readable string
-- @param ifid The integer interface id of the generated alert
-- @param alert The alert description table, including alert data such as the generating entity, timestamp, granularity, type
-- @param alert_type_params Table `alert_type_params` as built in the `:init` method
-- @return A human-readable string
function alert_device_protocol_not_allowed.format(ifid, alert, alert_type_params)
   local msg, devtype

   if ((not alert_type_params) or (alert_type_params == "")) then
      return i18n("alerts_dashboard.suspicious_device_protocol")
   end

   local discover = require("discover_utils")
   local forbidden_proto = alert_type_params["devproto_forbidden_id"] or 0

   if (alert_type_params["devproto_forbidden_peer"] == "cli") then
      msg = "flow_details.suspicious_client_device_protocol"
      devtype = alert_type_params["cli.devtype"]
   else
      msg = "flow_details.suspicious_server_device_protocol"
      devtype = alert_type_params["srv.devtype"]
   end

   if(devtype == nil) then
      return i18n("alerts_dashboard.suspicious_device_protocol")
   end

   local label = discover.devtype2string(devtype)
   return i18n(msg, {proto=interface.getnDPIProtoName(forbidden_proto), devtype=label,
      url=getDeviceProtocolPoliciesUrl("device_type="..
      devtype.."&l7proto="..forbidden_proto)})
end

-- #######################################################

return alert_device_protocol_not_allowed
