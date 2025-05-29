const std = @import("std");
const ad = @import("astrodate.zig");
const Year = ad.Year;
const Month = ad.Month;

// const mem = std.mem;
// const Allocator = std.mem.Allocator;

// A month will be printed in a grid of 4 to 6 rows and 7 columns.
// A 31-day month starting on the last day of the week will span 6 rows
// so that's why we need 6 x 7 = 42 cells.
const monthCal = [42]u8;    
const yearCal = [12]monthCal;
const monthLen = 3*7; // 3 chars per day, 7 days per week

const dayNames: [7][]const u8 = .{ "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa" };
const monthNames: [12][]const u8 = .{
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December"
};

pub fn printYearCalendar(
    year: Year,      // Gregorian year, e.g. 2025
    start: u32,     // Start of the week, 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    nCols: u32      // Number of month columns, e.g. 3
    ) !void {
    var yearTable: yearCal = undefined;
    var week: [monthLen]u8 = undefined; // 3 chars / day, 7 days per week

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    for (0..7) |i| {
        // Fill the week with day names
        week[i * 3 + 0] = dayNames[(start + i) % 7][0];
        week[i * 3 + 1] = dayNames[(start + i) % 7][1];
        week[i * 3 + 2] = ' ';
    }

    var month: Month = 1;
    for (&yearTable) |*monthTable| {
        makeMonthCalendar(monthTable, year, month, start);
        month += 1;
    }

    const gap = "   "; // 3 spaces for each month gap
    const nRows = @divTrunc(12, nCols) + @as(usize, if (12 % nCols == 0) 0 else 1); // Calculate number of rows needed

    // Print the year header
    var buf1: [8]u8 = undefined;
    const yearStr = try std.fmt.bufPrint(buf1[0..], "{d}", .{year});    

    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var buf2 = try allocator.alloc(u8, monthLen * nCols + (nCols - 1) * gap.len - 1);
    defer allocator.free(buf2);
    const yearHeader = centerStr(yearStr, buf2[0..], '='); // Center the year header
    try stdout.print("\n{s}\n\n", .{yearHeader});
    var r: usize = 0;
    while (r < nRows) : (r += 1) {
        // Print the month headers
        var c: usize = 0;
        while (c < nCols) : (c += 1) {
            const m: usize = (r * nCols + c);
            if (m < 12) {
                var buf3: [monthLen-1]u8 = undefined;
                const header = centerStr(monthNames[m], buf3[0..], '-'); // Center the month name
                // const header = try std.fmt.bufPrint(buf2[0..], "{s:-^20} ", .{monthNames[m]}); // Center the month name
                try stdout.print("{s} ", .{header});
                try stdout.print("{s}", .{gap}); // Print gap between months
            } else {
                break; // No more months to print
            }
        }
        try stdout.print("\n", .{});
        // Print the week days headers
        c = 0;
        while (c < nCols) : (c += 1) {
            const m: usize = (r * nCols + c);
            if (m < 12) {
                try stdout.print("{s}", .{week});
                try stdout.print("{s}", .{gap}); // Print gap between months
            } else {
                break; // No more months to print
            }
        }
        try stdout.print("\n", .{});
        var w: usize = 0; // Week row index
        while (w < 6) : (w += 1) {
            // Print the days of the month
            c = 0;
            while (c < nCols) : (c += 1) {
                const m: usize = (r * nCols + c);
                if (m < 12) {
                    const monthTable: []u8 = &yearTable[m];
                    var d: usize = 0;
                    while (d < 7) : (d += 1) { // 7 days per week
                        const day = monthTable[w * 7 + d];
                        if (day != 0) {
                            try stdout.print("{d:2} ", .{day});
                        } else {
                            try stdout.print("   ", .{}); // Empty cell
                        }
                    }
                    try stdout.print("{s}", .{gap}); // Print gap between months
                } else {
                    break; // No more months to print
                }
            }
            try stdout.print("\n", .{});
        }
    }
    try bw.flush(); // Don't forget to flush the buffered writer
}

pub fn printMonthCalendar(
    year: Year,     // Gregorian year, e.g. 2025
    month: Month,   // Month to print, 1 = January, 2 = February, ..., 12 = December
    start: u32,     // Start of the week, 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    ) !void {
    var monthTable: monthCal = undefined;

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var week: [monthLen]u8 = undefined; // 3 chars / day, 7 days per week

    for (0..7) |i| {
        // Fill the week with day names
        const j = i * 3;
        const k = (start + i) % 7;
        week[j + 0] = dayNames[k][0];
        week[j + 1] = dayNames[k][1];
        week[j + 2] = ' ';
    }

    var buf1: [monthLen]u8 = undefined;
    const monthName = try std.fmt.bufPrint(buf1[0..], " {s} {d} ", .{monthNames[month - 1], year});
    var buf2: [monthLen]u8 = undefined;
    const header = try std.fmt.bufPrint(buf2[0..], "{s:-^20}", .{monthName}); // Center the month name

    makeMonthCalendar(&monthTable, year, month, start);

    // Print the month header
    try stdout.print("\n{s}\n", .{header});

    // Print the week days header
    try stdout.print("{s}\n", .{week});

    // Print the month calendar
    var d: usize = 0;
    for (monthTable) |day| {
        if (day != 0) {
            try stdout.print("{d:2} ", .{day});
        } else {
            try stdout.print("   ", .{}); // Empty cell
        }
        d += 1;
        if (d % 7 == 0) { // End of week?
            try stdout.print("\n", .{});
        }
    }
    
    try stdout.print("\n", .{});
    try bw.flush(); // Don't forget to flush the buffered writer
}

// start: 0 = Sunday, 1 = Monday, ..., 6 = Saturday
fn makeMonthCalendar(monthTable: *monthCal, year: Year, month: Month, start: u32) void {
    var firstDay  = ad.AstroDate.dayOfWeek(.{.year=year, .month=month, .day=1});
    const numDays = ad.daysInMonth(year, month);
    // Rotate week days left so that 'start' is the first day of the week
    // and the first day of the month is at the correct position
    if (start <= firstDay) {
        firstDay -= start;
    } else {
        firstDay = (firstDay + 7) - start;
    }
    
    // Zero out the month calendar
    for (monthTable) |*day| {
        day.* = @as(u8,0); // Fill with zeroes
    }

    // Fill the month calendar
    var i: u8 = 1;
    for (monthTable[firstDay..firstDay+numDays]) |*day| {
        day.* = i;
        i += 1;       
    }
}

fn centerStr(str:[]const u8, buf: []u8, char: u8) []u8 {
    const len = str.len;
    const pad = (buf.len - len) / 2;
    const left_pad = pad;
    const right_pad = buf.len - len - left_pad;

    for (0..left_pad) |i| {
        buf[i] = char;
    }
    for (0..len) |i| {
        buf[left_pad + i] = str[i];
    }
    for (0..right_pad) |i| {
        buf[left_pad + len + i] = char;
    }
    buf[left_pad - 1] = ' '; // Ensure there's a space after the left padding
    buf[left_pad + len] = ' '; // Ensure there's a space after the string
    return buf;
}