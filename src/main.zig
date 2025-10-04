const std = @import("std");
const cal = @import("calendar.zig");
const ad = @import("astrodate.zig");
const Year = ad.Year;
const Month = ad.Month;
const Day = ad.Day;

var stderr_buffer: [2048]u8 = undefined;
var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
const stderr = &stderr_writer.interface;

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
            }
            if (std.mem.eql(u8, arg, "-c")) {
                args.ncols = 4; // Print 4 columns
            } else if (std.mem.eql(u8, arg, "-s")) {
                args.start = 1; // Start week on Monday
            } else {
                stderr.print("Unknown option: {s}\n", .{arg}) catch {};
                printHelp();
            }
            continue;
        }
        // Done with options, now handle arguments
        handle_options = false;
        if (list.len == 1) {
            // If only one argument left, it must be a year
            const year = std.fmt.parseInt(Year, arg, 10) catch { 
                stderr.print("Invalid year: {s}\n", .{arg}) catch {};
                printHelp();
            };
            args.year = year;
            break;
        } else if (list.len == 2) {
            // If two arguments left, they must be month and year
            const month = std.fmt.parseInt(Month, arg, 10) catch {
                stderr.print("Invalid month: {s}\n", .{arg}) catch {};
                printHelp();
            };
            if (month < 1 or month > 12) {
                stderr.print("Invalid month: {d}\n", .{month}) catch {};
                stderr.print("Month must be between 1 and 12.\n", .{}) catch {};
                printHelp();
            }
            args.month = month;
            const year = std.fmt.parseInt(Year,list[1], 10) catch {
                stderr.print("Invalid year: {s}\n", .{list[1]}) catch {};
                printHelp();
            };
            args.year = year;
            break;
        } else {
            stderr.print("Too many arguments.\n", .{}) catch {};
            printHelp();
        }
    }

    return args;
}

fn printHelp() noreturn {
    stderr.print("\n", .{}) catch {};
    stderr.print("Usage: zcal [options]            ; Print current month\n", .{})     catch {};
    stderr.print("       zcal [options] year       ; Print given year\n", .{})        catch {};
    stderr.print("       zcal [options] month year ; Print given month/year\n", .{})  catch {};
    stderr.print("options: -h,                     ; Show this help message\n", .{})  catch {};
    stderr.print("         -c                      ; Print year in 4 columns\n", .{}) catch {};
    stderr.print("         -s                      ; Start week on Monday\n", .{})    catch {};
    stderr.print("\n", .{}) catch {};
    stderr.flush() catch {};
    std.process.exit(1);
}

