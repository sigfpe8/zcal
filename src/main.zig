const std = @import("std");
const cal = @import("calendar.zig");
const ad = @import("astrodate.zig");
const Year = ad.Year;
const Month = ad.Month;
const Day = ad.Day;

pub fn main() !void {
    const args = try getArgs();
    if (args.year != 0 and args.month != 0) {
        // Print specific month/year
        try cal.printMonthCalendar(args.year, args.month, args.start);
    } else if (args.year != 0) {
        // Print specific year
        try cal.printYearCalendar(args.year, args.start, args.ncols);
    } else {
        // Print current month
        const now = ad.now();
        try cal.printMonthCalendar(now.year, now.month, args.start);
    }
}

const Args = struct {
    year:  Year,
    month: Month,
    start: u32, // Start of the week, 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    ncols: u32, // Number of columns to print
};

fn getArgs() !Args {
    var args = Args{
        .year = 0,
        .month = 0,
        .start = 0,  // Default start of the week (Sunday)
        .ncols = 3,  // Default number of columns
    };
    const args_list = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args_list);

    var list = args_list[1..];  // Skip program name
    var handle_options = true;

    while (list.len > 0) : (list = list[1..]) {
        const arg = list[0];
        if (arg[0] == '-' and handle_options) {
            // Handle options
            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                printHelp();
                std.process.exit(0);
            }
            if (std.mem.eql(u8, arg, "-c")) {
                args.ncols = 4; // Print 4 columns
            } else if (std.mem.eql(u8, arg, "-s")) {
                args.start = 1; // Start week on Monday
            } else {
                std.debug.print("Unknown option: {s}\n", .{arg});
                std.process.exit(1);
            }
            continue;
        }
        // Done with options, now handle arguments
        handle_options = false;
        if (list.len == 1) {
            // If only one argument left, it must be a year
            const year = std.fmt.parseInt(Year, arg, 10) catch { 
                std.debug.print("Invalid year: {s}\n", .{arg});
                std.process.exit(1);
            };
            args.year = year;
            break;
        } else if (list.len == 2) {
            // If two arguments left, it must be month and year
            const month = std.fmt.parseInt(Month, arg, 10) catch {
                std.debug.print("Invalid month: {s}\n", .{arg});
                std.process.exit(1);
            };
            args.month = month;
            const year = std.fmt.parseInt(Year,list[1], 10) catch {
                std.debug.print("Invalid year: {s}\n", .{list[1]});
                std.process.exit(1);
            };
            args.year = year;
            break;
        } else {
            std.debug.print("Too many arguments.\n", .{});
            printHelp();
            std.process.exit(1);
        }
    }

    return args;
}

fn printHelp() void {
    std.debug.print("\n", .{});
    std.debug.print("Usage: zcal [options]            ; Print current month\n", .{});
    std.debug.print("       zcal [options] year       ; Print given year\n", .{});
    std.debug.print("       zcal [options] month year ; Print given month/year\n", .{});
    std.debug.print("options: -h,                     ; Show this help message\n", .{});
    std.debug.print("         -c                      ; Print year in 4 columns\n", .{});
    std.debug.print("         -s                      ; Start week on Monday\n", .{});
    std.debug.print("\n", .{});
}

