--
-- (C) 2020 - ntop.org
--

--
-- This module implements the ICMP RTT probe.
--

local ts_utils = require("ts_utils_core")

local do_trace = false

-- #################################################################

-- This is the script state, which must be manually cleared in the check
-- function. Can be then used in the collect_results function to match the
-- probe requests with probe replies.
local result = {}

-- #################################################################

-- The function called periodically to send the host probes.
-- hosts contains the list of hosts to probe, The table keys are
-- the hosts identifiers, whereas the table values contain host information
-- see (am_utils.key2host for the details on such format).
local function check_http(hosts, granularity)
  result = {}

  for key, host in pairs(hosts) do
    local domain_name = host.host
    local full_url = string.format("%s://%s", host.measurement, domain_name)

    if do_trace then
      print("[RTT] GET "..full_url.."\n")
    end

    -- HTTP results are retrieved immediately
    local rv = ntop.httpGet(full_url, nil, nil, 10 --[[ timeout ]], false --[[ don't return content ]],
      nil, false --[[ don't follow redirects ]])

    if(rv and rv.HTTP_STATS and (rv.HTTP_STATS.TOTAL_TIME > 0)) then
      local total_time = rv.HTTP_STATS.TOTAL_TIME * 1000
      local lookup_time = (rv.HTTP_STATS.NAMELOOKUP_TIME or 0) * 1000
      local connect_time = (rv.HTTP_STATS.APPCONNECT_TIME or 0) * 1000

      result[key] = {
	resolved_addr = rv.RESOLVED_IP,
	value = total_time,
      }

      -- HTTP/S specific metrics
      if(host.measurement == "https") then
	ts_utils.append("am_host:https_stats_" .. granularity, {
	    ifid = getSystemInterfaceId(),
	    host = host.host,
	    measure = host.measurement,
	    lookup_ms = lookup_time,
	    connect_ms = connect_time,
	    other_ms = (total_time - lookup_time - connect_time),
	}, when)
      else
	ts_utils.append("am_host:http_stats_" .. granularity, {
	    ifid = getSystemInterfaceId(),
	    host = host.host,
	    measure = host.measurement,
	    lookup_ms = lookup_time,
	    other_ms = (total_time - lookup_time),
	}, when)
      end
    end
  end
end

-- #################################################################

-- The function responsible for collecting the results.
-- It must return a table containing a list of hosts along with their retrieved
-- measurement. The keys of the table are the host key. The values have the following format:
--  table
--	resolved_addr: (optional) the resolved IP address of the host
--	value: the measurement numeric value
local function collect_http(granularity)
  -- TODO: curl_multi_perform could be used to perform the requests
  -- asynchronously, see https://curl.haxx.se/libcurl/c/curl_multi_perform.html
  return(result)
end

-- #################################################################

return {
  -- Defines a list of measurements implemented by this script.
  -- The probing logic is implemented into the check() and collect_results().
  --
  -- Here is how the probing occurs:
  --	1. The check function is called with the list of hosts to probe. Ideally this
  --	   call should not block (e.g. should not wait for the results)
  --	2. The active_monitoring.lua code sleeps for some seconds
  --	3. The collect_results function is called. This should retrieve the results
  --       for the hosts checked in the check() function and return the results.
  --
  -- The alerts for non-responding hosts and the RTT timeseries are automatically
  -- generated by active_monitoring.lua . The timeseries are saved in the following schemas:
  -- "am_host:rtt_min", "am_host:rtt_5mins", "am_host:rtt_hour".
  measurements = {
    {
      -- The unique key for the measurement
      key = "http",
      -- The function called periodically to send the host probes
      check = check_http,
      -- The function responsible for collecting the results
      collect_results = collect_http,
      -- The granularities allowed for the probe. See supported_granularities in active_monitoring.lua
      granularities = {"min", "5mins", "hour"},
      -- The localization string for the measurement unit (e.g. "ms", "Mbits")
      i18n_unit = "active_monitoring_stats.msec",
      -- The localization string for the RTT timeseries menu entry
      i18n_rtt_ts_label = "graphs.num_ms_rtt",
      -- The operator to use when comparing the measurement with the threshold, "gt" for ">" or "lt" for "<".
      operator = "gt",
      -- A list of additional timeseries (the am_host:rtt_* is always shown) to show in the charts.
      -- See https://www.ntop.org/guides/ntopng/api/timeseries/adding_new_timeseries.html#charting-new-metrics .
      additional_timeseries = {{
	schema="am_host:http_stats",
	label=i18n("graphs.http_stats"),
	metrics_labels = { i18n("graphs.name_lookup"), i18n("other")},
      }},
      -- Js function to call to format the measurement value. See ntopng_utils.js .
      value_js_formatter = "fmillis",
      -- A list of additional notes (localization strings) to show into the timeseries charts
      i18n_chart_notes = {
	"active_monitoring_stats.other_http_descr",
      },
      -- If set, the user cannot change the host
      force_host = nil,
    }, {
      key = "https",
      check = check_http,
      collect_results = collect_http,
      granularities = {"min", "5mins", "hour"},
      i18n_unit = "active_monitoring_stats.msec",
      i18n_rtt_ts_label = "graphs.num_ms_rtt",
      operator = "gt",
      additional_timeseries = {{
	schema="am_host:https_stats",
	label=i18n("graphs.http_stats"),
	metrics_labels = { i18n("graphs.name_lookup"), i18n("graphs.app_connect"), i18n("other") },
      }},
      value_js_formatter = "fmillis",
      i18n_chart_notes = {
	"active_monitoring_stats.app_connect_descr",
	"active_monitoring_stats.other_https_descr"
      },
      force_host = nil,
    },
  },

  -- A setup function to possibly disable the plugin
  setup = nil,
}