// Many of the functions in this file are based on these books:
// [1] Meeus, Jean. (1998). "Astronomical Algorithms" 2nd ed. Willmann-Bell
// [2] Lawrence, J.L. (2018). "Celestial Calculations". The MIT Press
// [3] Collier, Peter. (2023). "Movement of the Spheres". Incomprehensible Books

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Year = i16; // Year can be negative, e.g. -1 = 2 BC, 0 = 1 BC, 1 = 1 AD...
pub const Month = u8; // Month is 1-based, i.e. 1 = January, 2 = February, ..., 12 = December
pub const Day = u8;   // Day is 1-based, i.e. 1 = 1st day of the month, ..., 31 = last day of the month

pub const UnixTime = i64; // Unix time is seconds since epoch (Jan 1, 1970); can be negative for dates before epoch

pub const AstroDate = struct {
    const Self = @This();

    // Date
    year:  Year,    // -1 = 2 BC, 0 = 1 BC, 1 = 1 AD...
    month: Month,   // 1 = Jan, 2 = Feb, ..., 12 = Dec
    day:   Day,     // Day number (1...31)

    // Time of day, default to midnight UTC (00:00:00)
    hour:  u8 = 0,  // Hour number (0...23)
    min:   u8 = 0,  // Minute number (0...59)
    sec:   u8 = 0,  // Second number (0...59)
    tz:    i8 = 0,  // Timezone offset in hours (e.g. -5 for EST)


    // The day following
    //   1582 October  4 Thursday (Julian Calendar) was 
    //   1582 October 15 Friday   (Gregorian Calendar)

    // Return true if the given date is in the Julian Calendar
    // (i.e. before 1582 October 5)
    pub fn inJulianCalendar(self: Self) bool {
        return (self.year < 1582 or
               (self.year == 1582 and ((self.month < 10) or
                                       (self.month == 10 and self.day < 5))));
    }

    // Return true if the given date is in the Gregorian Calendar
    // (i.e. after 1582 October 14)
    pub fn inGregorianCalendar(self: Self) bool {
        return (self.year > 1582 or
               (self.year == 1582 and ((self.month > 10) or
                                       (self.month == 10 and self.day > 14))));
    }


    // Return the Julian Day Number (JD) of the given date
    // JD 0.0 = 4713 B.C. (-4712) January 1 at noon
    // [1] p 59-61
    pub fn JD(self: Self) f64 {
        var yr: f64 = @floatFromInt(self.year);
        var mo: f64 = @floatFromInt(self.month);
        const dy: f64 = @as(f64,@floatFromInt(self.day))
            + @as(f64,@floatFromInt(self.hour)) / 24
            + @as(f64,@floatFromInt(self.min)) / 1440
            + @as(f64,@floatFromInt(self.sec)) / 86400;

        if (self.month <= 2) {
            yr -= 1;
            mo += 12;
        }

        var B: f64 = 0;

        // Gregorian Calendar?
        if (inGregorianCalendar(self)) {
            const A: f64 = @trunc(yr / 100);  // Century
            B = 2 - A + @trunc(A / 4);
        }

        return @trunc(365.25 * (yr + 4716))
            + @trunc(30.6001 * (mo + 1))
            + dy
            + B
            - 1524.5;
    }

    // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    pub fn dayOfWeek(self: Self) u32 {
        const jd: u32 = @intFromFloat(JD(self) + 1.5);
        return @rem(jd,7);
    }

    // Return "YYYY-MM-DD" for YYYY > 0 (i.e. AD)
    //        "YYYY-MM-DD BC" for YYYY <= 0
    pub fn toStringDate(self: Self, allocator: Allocator) ![]const u8 {
        if (self.year > 0) {
            return try std.fmt.allocPrint(allocator, "{d:0>4}-{d:0>2}-{d:0>2}", .{
                @as(u32, @intCast(self.year)),
                @as(u32, self.month),
                @as(u32, self.day),
            });
        }

        return try std.fmt.allocPrint(allocator, "{d:0>4}-{d:0>2}-{d:0>2} BC", .{
            @as(u32, @intCast(-self.year + 1)),
            @as(u32, self.month),
            @as(u32, self.day),
        });
    }

    // Return "HH:MM:SS"
    pub fn toStringTime(self: Self, allocator: Allocator) ![]const u8 {
        return try std.fmt.allocPrint(allocator, "{d:0>2}:{d:0>2}:{d:0>2}", .{
            @as(u32, self.hour),
            @as(u32, self.min),
            @as(u32, self.sec)
        });
    }

    // Return "YYYY-MM-DD HH:MM:SS" for YYYY > 0 (i.e. AD)
    //        "YYYY-MM-DD BC HH:MM:SS" for YYYY <= 0
    pub fn toStringDateTime(self: Self, allocator: Allocator) ![]const u8 {
        const date_str = try self.toStringDate(allocator);
        defer allocator.free(date_str);
        const time_str = try self.toStringTime(allocator);
        defer allocator.free(time_str);
        return try std.fmt.allocPrint(allocator, "{s} {s}", .{date_str, time_str});
    }
};

// Return true if the given year is a leap year
pub fn isLeapYear(year: Year) bool {
  // Julian Calendar?
  // Note that 1582 itself is not a leap year
  if (year <= 1582) {
    return @rem(year,4) == 0;
  }
  // Gregorian Calendar
  return (@rem(year,4) == 0 and (@rem(year,100) != 0 or @rem(year,400) == 0));
}

// Return the number of days in the given month
const daysPerMonth = [_]u32{
    31, // January
    28, // February
    31, // March
    30, // April
    31, // May
    30, // June
    31, // July
    31, // August
    30, // September
    31, // October
    30, // November
    31, // December
};

pub fn daysInMonth(year: Year, month: Month) u32 {
    if (month == 2) {
        return if (isLeapYear(year)) 29 else 28;
    }
    return daysPerMonth[month - 1]; 
}

// Convert Unix time to AstroDate
pub fn unixTimeToAstroDate(ts: UnixTime) AstroDate {
    // TODO: handle negative timestamps (before 1970)
    var ndays = @divTrunc(ts, std.time.s_per_day)+1;   // Number of days since epoch, including this day
    const secs_today = @rem(ts, std.time.s_per_day);         // Seconds since midnight

    var tmp = secs_today;
    const hour: u8 = @truncate(@as(u64,@bitCast(@divTrunc(tmp, std.time.s_per_hour))));
    tmp = @rem(tmp, std.time.s_per_hour);
    const min:  u8 = @truncate(@as(u64,@bitCast(@divTrunc(tmp, std.time.s_per_min))));
    const sec:  u8 = @truncate(@as(u64,@bitCast(@rem(tmp, std.time.s_per_min))));

    var year: Year = 1970;
    var month: Month = 1;

    var days_in_year: u32 = if (isLeapYear(year)) 366 else 365;
    while (ndays > days_in_year) {
        ndays -= days_in_year;
        year += 1;
        days_in_year = if (isLeapYear(year)) 366 else 365;
    }

    var days_in_month = daysInMonth(year, month);
    while (ndays > days_in_month) {
        ndays -= days_in_month;
        month += 1;
        days_in_month = daysInMonth(year, month);
    }

    const day: Day = @truncate(@as(u64,@bitCast(ndays)));

    return AstroDate{ .year = year, .month = month, .day = day,
                      .hour = hour, .min = min, .sec = sec };
}

pub fn now() AstroDate {
    const ts: UnixTime = std.time.timestamp();
    return unixTimeToAstroDate(ts);
}

// Return the date of Easter Sunday for the given year
// [1] p 67
pub fn easterDate(year: usize) AstroDate {
    // Works only for years after 1582 (Gregorian Calendar)
    const a = @rem(year, 19);
    const b = @divTrunc(year, 100);
    const c = @rem(year, 100);
    const d = @divTrunc(b, 4);
    const e = @rem(b, 4);
    const f = @divTrunc((b + 8), 25);
    const g = @divTrunc((b - f + 1), 3);
    const h = @rem(19 * a + b - d - g + 15, 30);
    const i = @divTrunc(c, 4);
    const k = @rem(c, 4);
    const l = @rem(32 + 2 * e + 2 * i - h - k, 7);
    const m = @divTrunc(a + 11 * h + 22 * l, 451);
    const x = h + l - 7 * m + 114;
    const month = @divTrunc(x, 31);
    const day = @rem(x, 31) + 1;
    return .{.year = @as(u15,@truncate(year)),
             .month  = @as(u8,@truncate(month)),
             .day    = @as(u8,@truncate(day))};
}

const expect = std.testing.expect;
const print = std.debug.print;
//const DebugAllocator = @import("heap.debug_allocator").DebugAllocator;

test "dayOfWeek" {
    try expect(AstroDate.dayOfWeek(.{.year = 2000, .month = 1,  .day =  1}) == 6);
    try expect(AstroDate.dayOfWeek(.{.year = 1987, .month = 1,  .day = 27}) == 2);
    try expect(AstroDate.dayOfWeek(.{.year = 1987, .month = 6,  .day = 19}) == 5);
    try expect(AstroDate.dayOfWeek(.{.year = 1957, .month = 10, .day =  4}) == 5);
    try expect(AstroDate.dayOfWeek(.{.year = 1954, .month = 6,  .day = 30}) == 3);
    try expect(AstroDate.dayOfWeek(.{.year = 1582, .month = 10, .day = 15}) == 5);
    try expect(AstroDate.dayOfWeek(.{.year = 1582, .month = 10, .day =  4}) == 4);
}

test "isLeapYear" {
    try expect(isLeapYear(0) == true);
    try expect(isLeapYear(4) == true);
    try expect(isLeapYear(10) == false);
    try expect(isLeapYear(1500) == true);
    try expect(isLeapYear(1600) == true);
    try expect(isLeapYear(1700) == false);
    try expect(isLeapYear(1895) == false);
    try expect(isLeapYear(1900) == false);
    try expect(isLeapYear(2000) == true);
    try expect(isLeapYear(2020) == true);
    try expect(isLeapYear(2021) == false);
    try expect(isLeapYear(2024) == true);
}

test "toStringDate" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const date = AstroDate{.year = 2000, .month = 1, .day = 1, .hour = 12};
    const date_str = try date.toStringDate(allocator);
    try expect(std.mem.eql(u8, date_str, "2000-01-01"));
    allocator.free(date_str);
}

test "toStringTime" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const date = AstroDate{.year = 2000, .month = 1, .day = 1, .hour = 12, .min = 30, .sec = 30 };
    const time_str = try date.toStringTime(allocator);
    try expect(std.mem.eql(u8, time_str, "12:30:30"));
    allocator.free(time_str);
}

test "toStringDateTime" {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const date = AstroDate{.year = 2025, .month = 5, .day = 23, .hour = 23, .min = 59, .sec = 59};
    const date_time_str = try date.toStringDateTime(allocator);
    try expect(std.mem.eql(u8, date_time_str, "2025-05-23 23:59:59"));
    allocator.free(date_time_str);
}

test "easterDate" {
    var date = easterDate(1818);
    try expect(date.year == 1818 and date.month == 3 and date.day == 22);

    date = easterDate(1886);    
    try expect(date.year == 1886 and date.month == 4 and date.day == 25);    

    date = easterDate(1954);
    try expect(date.year == 1954 and date.month == 4 and date.day == 18);
    
    date = easterDate(1961);
    try expect(date.year == 1961 and date.month == 4 and date.day == 2);

    date = easterDate(1991);
    try expect(date.year == 1991 and date.month == 3 and date.day == 31);

    date = easterDate(1992);
    try expect(date.year == 1992 and date.month == 4 and date.day == 19);

    date = easterDate(1993);
    try expect(date.year == 1993 and date.month == 4 and date.day == 11);

    date = easterDate(2000);
    try expect(date.year == 2000 and date.month == 4 and date.day == 23);

    date = easterDate(2025);
    try expect(date.year == 2025 and date.month == 4 and date.day == 20);

    date = easterDate(2026);
    try expect(date.year == 2026 and date.month == 4 and date.day == 5);

    date = easterDate(2038);
    try expect(date.year == 2038 and date.month == 4 and date.day == 25);

    date = easterDate(2285);
    try expect(date.year == 2285 and date.month == 3 and date.day == 22);
}

test "unixTimeToAstroDate" {
    // TODO: handle negative timestamps (before 1970)
    var date = unixTimeToAstroDate(0); // Unix epoch
    try expect(date.year == 1970 and date.month == 1 and date.day == 1 and date.hour == 0 and date.min == 0 and date.sec == 0);

    date = unixTimeToAstroDate(86400); // One day later
    try expect(date.year == 1970 and date.month == 1 and date.day == 2 and date.hour == 0 and date.min == 0 and date.sec == 0);

    date = unixTimeToAstroDate(86400*365-1); // Last day of 1970
    try expect(date.year == 1970 and date.month == 12 and date.day == 31 and date.hour == 23 and date.min == 59 and date.sec == 59);

    date = unixTimeToAstroDate(86400*365);  // First day of 1971
    try expect(date.year == 1971 and date.month == 1 and date.day == 1 and date.hour == 0 and date.min == 0 and date.sec == 0);

    date = unixTimeToAstroDate(1672531199); // Last second of 2022
    try expect(date.year == 2022 and date.month == 12 and date.day == 31 and date.hour == 23 and date.min == 59 and date.sec == 59);
}
