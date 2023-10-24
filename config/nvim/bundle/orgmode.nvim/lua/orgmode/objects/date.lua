-- TODO
-- Support diary format and format without short date name
local spans = { d = 'day', m = 'month', y = 'year', h = 'hour', w = 'week' }
local config = require('orgmode.config')
local utils = require('orgmode.utils')
local Range = require('orgmode.parser.range')
local pattern = '([<%[])(%d%d%d%d%-%d?%d%-%d%d[^>%]]*)([>%]])'
local date_format = '%Y-%m-%d'
local time_format = '%H:%M'

---@class Date
---@field type string
---@field active boolean
---@field date_only boolean
---@field range Range
---@field day number
---@field month number
---@field year number
---@field hour number
---@field min number
---@field timestamp number
---@field timestamp_end number
---@field is_date_range_start boolean
---@field is_date_range_end boolean
---@field related_date_range Date
---@field dayname string
---@field adjustments string[]
local Date = {}

---@param source table
---@param target table
---@return table
local function set_date_opts(source, target)
  target = target or {}
  for _, field in ipairs({'year', 'month', 'day'}) do
    target[field] = source[field]
  end
  for _, field in ipairs({'hour', 'min'}) do
    target[field] = source[field] or 0
  end
  return target
end

---@param data table
function Date:new(data)
  data = data or {}
  local date_only = data.date_only or (not data.hour and not data.min)
  local opts = set_date_opts(data)
  opts.type = data.type or 'NONE'
  opts.active = data.active or false
  opts.range = data.range
  opts.timestamp = os.time(opts)
  opts.date_only = date_only
  opts.dayname = os.date('%a', opts.timestamp)
  opts.adjustments = data.adjustments or {}
  opts.timestamp_end = data.timestamp_end
  opts.is_date_range_start = data.is_date_range_start or false
  opts.is_date_range_end = data.is_date_range_end or false
  opts.related_date_range = data.related_date_range or nil
  setmetatable(opts, self)
  self.__index = self
  return opts
end

---@param time table
---@return Date
function Date:from_time_table(time)
  local range_diff = self.timestamp_end and self.timestamp_end - self.timestamp or 0
  local timestamp = os.time(set_date_opts(time))
  local opts = set_date_opts(os.date('*t', timestamp))
  opts.date_only = self.date_only
  opts.dayname = self.dayname
  opts.adjustments = self.adjustments
  opts.type = self.type
  opts.active = self.active
  opts.range = self.range
  if self.timestamp_end then
    opts.timestamp_end = timestamp + range_diff
  end
  opts.is_date_range_start = self.is_date_range_start
  opts.is_date_range_end = self.is_date_range_end
  opts.related_date_range = self.related_date_range
  return Date:new(opts)
end

---@param opts table
---@return Date
function Date:set(opts)
  opts = opts or {}
  local date = os.date('*t', self.timestamp)
  for opt, val in pairs(opts) do
    date[opt] = val
  end
  return self:from_time_table(date)
end

---@param opts table
---@return Date
function Date:clone(opts)
  local date = Date:new(self)
  for opt, val in pairs(opts or {}) do
    date[opt] = val
  end
  return date
end

---@param date string
---@param dayname string
---@param time string
---@param adjustments string
---@param data table
---@return Date
local function parse_datetime(date, dayname, time, time_end, adjustments, data)
  local date_parts = vim.split(date, '-')
  local time_parts = vim.split(time, ':')
  local opts = {
    year = tonumber(date_parts[1]),
    month = tonumber(date_parts[2]),
    day = tonumber(date_parts[3]),
    hour = tonumber(time_parts[1]),
    min = tonumber(time_parts[2]),
  }
  opts.dayname = dayname
  opts.adjustments = adjustments
  if time_end then
    local time_end_parts = vim.split(time_end, ':')
    opts.timestamp_end = os.time({
      year = tonumber(date_parts[1]),
      month = tonumber(date_parts[2]),
      day = tonumber(date_parts[3]),
      hour = tonumber(time_end_parts[1]),
      min = tonumber(time_end_parts[2])
    })
  end
  opts = vim.tbl_extend('force', opts, data or {})
  return Date:new(opts)
end

---@param date string
---@param dayname string
---@param adjustments string
---@param data table
---@return Date
local function parse_date(date, dayname, adjustments, data)
  local date_parts = vim.split(date, '-')
  local opts = {
    year = tonumber(date_parts[1]),
    month = tonumber(date_parts[2]),
    day = tonumber(date_parts[3]),
  }
  opts.adjustments = adjustments
  opts.dayname = dayname
  opts = vim.tbl_extend('force', opts, data or {})
  return Date:new(opts)
end


---@return Date
local function today()
  local opts = os.date('*t', os.time())
  opts.date_only = true
  return Date:new(opts)
end

---@return Date
local function now()
  local opts = os.date('*t', os.time())
  return Date:new(opts)
end

---@param datestr string
---@return string|nil
local function is_valid_date(datestr)
  return datestr:match('^%d%d%d%d%-%d%d%-%d%d%s+') or datestr:match('^%d%d%d%d%-%d%d%-%d%d$')
end

---@param datestr string
---@param opts table
---@return Date
local function from_string(datestr, opts)
  if not is_valid_date(datestr) then
    return now().clone(opts)
  end
  local parts = vim.split(datestr, '%s+')
  local date = table.remove(parts, 1)
  local dayname = nil
  local time = nil
  local time_end = nil
  local adjustments = {}
  for _, part in ipairs(parts) do
    if part:match('%a%a%a') then
      dayname = part
    elseif part:match('%d?%d:%d%d%-%d?%d:%d%d') then
      local times = vim.split(part, '-')
      time = times[1]
      time_end = times[2]
    elseif part:match('%d?%d:%d%d') then
      time = part
    elseif part:match('[%.%+%-]+%d+[hdwmy]?') then
      table.insert(adjustments, part)
    end
  end

  if time then
    return parse_datetime(date, dayname, time, time_end, adjustments, opts)
  end

  return parse_date(date, dayname, adjustments, opts)
end

---@return string
function Date:to_string()
  local date = ''
  local format = date_format
  if self.dayname then
    format = format..' %a'
  end

  if self.date_only then
    date = os.date(format, self.timestamp)
  else
    date = os.date(format..' '..time_format, self.timestamp)
    if self.timestamp_end then
      date = date..'-'..os.date(time_format, self.timestamp_end)
    end
  end

  if #self.adjustments > 0 then
    date = date..' '..table.concat(self.adjustments, ' ')
  end

  return date
end

---@return string
function Date:format_time()
  if self.date_only then return '' end
  local t = self:format(time_format)
  if self.timestamp_end then
    t = t..'-'..os.date(time_format, self.timestamp_end)
  end
  return t
end

---@param value string
---@return Date
function Date:adjust(value)
  local adjustment = self:_parse_adjustment(value)
  local modifier = { [adjustment.span] = adjustment.amount }
  if adjustment.is_negative then
    return self:subtract(modifier)
  end
  return self:add(modifier)
end

---@param value string
---@return table
function Date:_parse_adjustment(value)
  local operation, amount, span = value:match('^([%+%-])(%d+)([hdwmy]?)')
  if not operation or not amount then
    return { span = 'day', amount = 0 }
  end
  if not span or span == '' then
    span = 'd'
  end
  return {
    span = spans[span],
    amount = tonumber(amount),
    is_negative = operation == '-'
  }
end

---@param span string
---@return Date
function Date:start_of(span)
  if #span == 1 then
    span = spans[span]
  end
  local opts = {
    day =  { hour = 0, min = 0 },
    month = { day = 1, hour = 0, min = 0 },
    year = { month = 1, day = 1, hour = 0, min = 0 },
    hour = { min = 0 }
  }
  if opts[span] then
    return self:set(opts[span])
  end

  if span == 'week' then
    local this = self
    local date = os.date('*t', self.timestamp)
    while date.wday ~= config:get_week_start_day_number() do
      this = this:adjust('-1d')
      date = os.date('*t', this.timestamp)
    end
    return this:set(opts.day)
  end

  return self
end

---@param span string
---@return Date
function Date:end_of(span)
  if #span == 1 then
    span = spans[span]
  end
  local opts = {
    day = { hour = 23, min = 59 },
    year = { month = 12, day = 31, hour = 23, min = 59 },
    hour = { min = 59 }
  }

  if opts[span] then
    return self:set(opts[span])
  end

  if span == 'week' then
    local this = self
    local date = os.date('*t', self.timestamp)
    while date.wday ~= config:get_week_end_day_number() do
      this = this:adjust('+1d')
      date = os.date('*t', this.timestamp)
    end
    return this:set(opts.day)
  end

  if span == 'month'then
    return self:add({ month = 1 }):start_of('month'):adjust('-1d'):end_of('day')
  end

  return self
end

---@return number
function Date:get_isoweekday()
  local date = os.date('*t', self.timestamp)
  return utils.convert_to_isoweekday(date.wday)
end

---@return number
function Date:get_weekday()
  local date = os.date('*t', self.timestamp)
  return date.wday
end

---@param isoweekday number
---@param future? boolean
---@return Date
function Date:set_isoweekday(isoweekday, future)
  local current_isoweekday = self:get_isoweekday()
  if isoweekday <= current_isoweekday then
    return self:subtract({ day = current_isoweekday - isoweekday })
  end
  if future then
    return self:add({ day = isoweekday - current_isoweekday })
  end
  return self:subtract({ week = 1 }):add({ day = isoweekday - current_isoweekday })
end

---@param opts table
---@return Date
function Date:add(opts)
  opts = opts or {}
  local date = os.date('*t', self.timestamp)
  for opt, val in pairs(opts) do
    if opt == 'week' then
      opt = 'day'
      val = val * 7
    end
    date[opt] = date[opt] + val
  end
  return self:from_time_table(date)
end

---@param opts table
---@return Date
function Date:subtract(opts)
  opts = opts or {}
  for opt, val in pairs(opts) do
    opts[opt] = -val
  end
  return self:add(opts)
end

---@param date Date
---@param span string
---@return boolean
function Date:is_same(date, span)
  if not span then
    return self.timestamp == date.timestamp
  end
  return self:start_of(span).timestamp == date:start_of(span).timestamp
end

---@param from Date
---@param to Date
---@param span string
---@return boolean
function Date:is_between(from, to, span)
  local f = from
  local t = to
  if span then
    f = from:start_of(span)
    t = to:end_of(span)
  end
  return self.timestamp >= f.timestamp and self.timestamp <= t.timestamp
end

---@param date Date
---@param span string
---@return boolean
function Date:is_before(date, span)
  return not self:is_same_or_after(date, span)
end

---@param date Date
---@param span string
---@return boolean
function Date:is_same_or_before(date, span)
  local d = date
  local s = self
  if span then
    d = date:start_of(span)
    s = self:start_of(span)
  end
  return s.timestamp <= d.timestamp
end

---@param date Date
---@param span string
---@return boolean
function Date:is_after(date, span)
  return not self:is_same_or_before(date, span)
end

---@param date Date
---@param span string
---@return boolean
function Date:is_same_or_after(date, span)
  local d = date
  local s = self
  if span then
    d = date:start_of(span)
    s = self:start_of(span)
  end
  return s.timestamp >= d.timestamp
end

---@return boolean
function Date:is_today()
  if self.is_today_date == nil then
    local date = now()
    self.is_today_date = date.year == self.year and date.month == self.month and date.day == self.day
  end
  return self.is_today_date
end

---@return boolean
function Date:is_obsolete_range_end()
  return self.is_date_range_end and self.related_date_range:is_same(self, 'day')
end

---Return number of days for a date range
---@return number
function Date:get_date_range_days()
  if not self:is_none() or not self.related_date_range then return 0 end
  return math.abs(self.related_date_range:diff(self)) + 1
end

---@param date Date
---@return boolean
function Date:is_in_date_range(date)
  if self.is_date_range_start then
    local ranges_same_day = self.related_date_range:is_obsolete_range_end()
    if ranges_same_day then
      return false
    end
    return date:is_between(self, self.related_date_range:subtract({ day = 1 }), 'day')
  end
  return false
end

---@param date Date
---@return Date[]
function Date:get_range_until(date)
  local this = self
  local dates = {}
  while this.timestamp < date.timestamp do
    table.insert(dates, this)
    this = this:add({ day = 1 })
  end
  return dates
end

---@param format string
---@return string
function Date:format(format)
  return os.date(format, self.timestamp)
end

---@param from Date
---@return number
function Date:diff(from)
  local diff = self:start_of('day').timestamp - from:start_of('day').timestamp
  local day = 86400
  return math.floor(diff / day)
end

---@param span string
---@return boolean
function Date:is_past(span)
  return self:is_before(now(), span)
end

---@param span string
---@return boolean
function Date:is_today_or_past(span)
  return self:is_same_or_before(now(), span)
end

---@param span string
---@return boolean
function Date:is_future(span)
  return self:is_after(now(), span)
end

---@param span string
---@return boolean
function Date:is_today_or_future(span)
  return self:is_same_or_after(now(), span)
end

---@param from Date
---@return string
function Date:humanize(from)
  from = from or now()
  local diff = self:diff(from)
  if diff == 0 then
    return 'Today'
  end
  if diff < 0 then
    return math.abs(diff)..' d. ago'
  end
  return 'In '..diff..' d.'
end

---@return boolean
function Date:is_deadline()
  return self.active and self.type == 'DEADLINE'
end

---@return boolean
function Date:is_none()
  return self.active and self.type == 'NONE'
end

---@return boolean
function Date:is_scheduled()
  return self.active and self.type == 'SCHEDULED'
end

---@return boolean
function Date:is_closed()
  return self.type == 'CLOSED'
end

---@return boolean
function Date:is_weekend()
  local isoweekday = self:get_isoweekday()
  return isoweekday >= 6
end

---@return string
function Date:get_negative_adjustment()
  if #self.adjustments == 0 then return nil end
  for _, adj in ipairs(self.adjustments) do
    if adj:match('^%-%d+') then
      return adj
    end
  end
  return nil
end

---Get repeater value (ex. +1w, .+1w, ++1w)
---@return string
function Date:get_repeater()
  if #self.adjustments == 0 then return nil end

  for _, adj in ipairs(self.adjustments) do
    if adj:match('^[%+%.]?%+%d+') then
      return adj
    end
  end
  return nil
end

function Date:set_todays_date()
  local time = os.date('*t', os.time())
  return self:set({
    year = time.year,
    month = time.month,
    day = time.day,
  })
end

function Date:apply_repeater()
  local repeater = self:get_repeater()
  local date = self
  local current_time = now()
  if not repeater then return self end
  if repeater:match('^%.%+%d+') then
    return date:set_todays_date():adjust(repeater:sub(2))
  end
  if repeater:match('^%+%+%d') then
    while date.timestamp < current_time.timestamp do
      date = date:adjust(repeater:sub(2))
    end
    return date
  end

  return date:adjust(repeater)
end

---@param date Date
---@return boolean
function Date:repeats_on(date)
  local repeater = self:get_repeater()
  if not repeater then return false end
  repeater = repeater:gsub('^%.', ''):gsub('^%+%+', '+')
  local repeat_date = self:start_of('day')
  local date_start = date:start_of('day')
  while repeat_date.timestamp < date_start.timestamp do
    repeat_date = repeat_date:adjust(repeater)
  end
  return repeat_date:is_same(date, 'day')
end

---@return Date
function Date:get_adjusted_date()
  if not self:is_deadline() and not self:is_scheduled() then
    return self
  end

  local adjustment = self:get_negative_adjustment()

  if self:is_deadline() then
    local warning_days = config.org_deadline_warning_days
    local span = 'day'
    if adjustment then
      local adj = self:_parse_adjustment(adjustment)
      warning_days = adj.amount
      span = adj.span
    end
    return self:subtract({ [span] = warning_days })
  end

  if not adjustment then return self end
  local adj = self:_parse_adjustment(adjustment)
  return self:add({ day = adj.amount })
end

---@return number
function Date:get_week_number()
  local start_of_year = self:start_of('year')
  local week = 1
  while start_of_year.timestamp < self.timestamp do
    start_of_year = start_of_year:add({ week = 1 })
    week = week + 1
  end
  return week
end

---@param line string
---@param lnum number
---@param open string
---@param datetime string
---@param close string
---@param last_match? Date
---@param type? string
---@return Date
local function from_match(line, lnum, open, datetime, close, last_match, type)
  local search_from = last_match and last_match.range.end_col or 0
  local from, to = line:find(vim.pesc(open..datetime..close), search_from)
  local is_date_range_end = last_match and last_match.is_date_range_start and line:sub(from - 2, from - 1) == '--'
  local opts = {
    type = type,
    active = open == '<',
    range = Range:new({ start_line = lnum, end_line = lnum, start_col = from, end_col = to }),
    is_date_range_start = line:sub(to + 1, to + 2) == '--'
  }
  local parsed_date = from_string(vim.trim(datetime), opts)
  if is_date_range_end then
    parsed_date.is_date_range_end = true
    parsed_date.related_date_range = last_match
    last_match.related_date_range = parsed_date
  end

  return parsed_date
end

---@param line string
---@param lnum number
---@return Date[]
local function parse_all_from_line(line, lnum)
  local dates = {}
  for open, datetime, close in line:gmatch(pattern) do
    table.insert(dates, from_match(line, lnum, open, datetime, close, dates[#dates]))
  end
  return dates
end

return {
  from_string = from_string,
  now = now,
  today = today,
  parse_all_from_line = parse_all_from_line,
  is_valid_date = is_valid_date,
  from_match = from_match,
  pattern = pattern
}
