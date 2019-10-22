//
//  ALLogger.m
//
//  Created by Matt Coneybeare on 09/1/13.
//  Copyright (c) 2013 Urban Apps, LLC. All rights reserved.
//

#import "ALLogger.h"


// We use static class vars because ALLogger only has class methods
static BOOL				UA__shouldLogInProduction	= NO;
static BOOL				UA__shouldLogInDebug		= YES;
static BOOL				UA__userDefaultsOverride	= NO;
static NSString			*UA__verbosityFormatPlain	= nil;
static NSString			*UA__verbosityFormatBasic	= nil;
static NSString			*UA__verbosityFormatFull	= nil;
static NSString			*UA__bundleName				= nil;
static NSString			*UA__userDefaultsKey		= nil;
static ALLoggerSeverity	UA__minimumSeverity			= ALLoggerSeverityUnset;
static NSInteger		UA__maxLogsRetained			= 200;


@implementation ALLogger
	
#pragma mark - Setup
	
+ (void)initialize {
	[super initialize];
	[self setupDefaultFormats];
	[self observeUserDefaultsKey];
}
	
+ (void)setupDefaultFormats {
	// Setup default formats
	
	// ALLoggerVerbosityPlain is simple called with:
	//
	// 1. [NSString stringWithFormat:(s), ##__VA_ARGS__]:
	//
	[ALLogger setFormat:@"%@" forVerbosity:ALLoggerVerbosityPlain];
	
	
	// ALLoggerVerbosityBasic is formatted with arguments passed in this order:
	//
	//	1. [[NSString stringWithUTF8String:__FILE__] lastPathComponent]
	//	2. [NSNumber numberWithInt:__LINE__]
	//	3. [NSString stringWithFormat:(s), ##__VA_ARGS__] ]
	//
	[ALLogger setFormat:@"<%@:%@> %@" forVerbosity:ALLoggerVerbosityBasic];
	
	
	// ALLoggerVerbosityFull is formatted with arguments passed in this order:
	//
	//	1. self
	//	2. [[NSString stringWithUTF8String:__FILE__] lastPathComponent]
	//	3. [NSNumber numberWithInt:__LINE__]
	//	4. NSStringFromSelector(_cmd)
	//	5. [NSString stringWithFormat:(s), ##__VA_ARGS__]
	//
	[ALLogger setFormat:@"<%p %@:%@ (%@)> %@" forVerbosity:ALLoggerVerbosityFull];
}
	
+ (NSString *)formatForVerbosity:(ALLoggerVerbosity)verbosity {
	switch (verbosity) {
		case ALLoggerVerbosityNone:		return nil;
		case ALLoggerVerbosityPlain:	return UA__verbosityFormatPlain;
		case ALLoggerVerbosityBasic:	return UA__verbosityFormatBasic;
		case ALLoggerVerbosityFull:		return UA__verbosityFormatFull;
		default:
		return nil;
	}
}
	
+ (void)resetDefaultLogFormats {
	[self setupDefaultFormats];
}
	
+ (void)setMinimumSeverity:(ALLoggerSeverity)severity {
	UA__minimumSeverity = severity;
}
	
+ (ALLoggerSeverity)minimumSeverity {
	return UA__minimumSeverity;
}
	
+ (NSString *)labelForSeverity:(ALLoggerSeverity)severity {
	switch (severity) {
		case ALLoggerSeverityDebug: return @"DEBUG";
		case ALLoggerSeverityInfo:  return @"INFO";
		case ALLoggerSeverityWarn:	return @"WARN";
		case ALLoggerSeverityError:	return @"ERROR";
		case ALLoggerSeverityFatal:	return @"FATAL";
		default: return @"";
	}
}
	
+ (BOOL)usingSeverityFiltering {
	return ALLoggerSeverityUnset != [ALLogger minimumSeverity];
}
	
+ (BOOL)meetsMinimumSeverity:(ALLoggerSeverity)severity {
	return severity >= [ALLogger minimumSeverity];
}
	
+ (BOOL)shouldLogInProduction {
	return UA__shouldLogInProduction;
}
	
+ (void)setShouldLogInProduction:(BOOL)shouldLogInProduction {
	UA__shouldLogInProduction = shouldLogInProduction;
}
	
+ (BOOL)shouldLogInDebug {
	return UA__shouldLogInDebug;
}
	
+ (void)setShouldLogInDebug:(BOOL)shouldLogInDebug {
	UA__shouldLogInDebug = shouldLogInDebug;
}
	
+ (BOOL)userDefaultsOverride {
	return UA__userDefaultsOverride;
}
	
+ (void)setUserDefaultsOverride:(BOOL)userDefaultsOverride {
	UA__userDefaultsOverride = userDefaultsOverride;
}
	
	
+ (void)setFormat:(NSString *)format forVerbosity:(ALLoggerVerbosity)verbosity {
	switch (verbosity) {
		case ALLoggerVerbosityNone: return;
		case ALLoggerVerbosityPlain:
		UA__verbosityFormatPlain = format;
		break;
		case ALLoggerVerbosityBasic:
		UA__verbosityFormatBasic = format;
		break;
		case ALLoggerVerbosityFull:
		UA__verbosityFormatFull = format;
		break;
	}
}
	
#pragma mark - Logging
	
+ (BOOL)isProduction {
#ifdef DEBUG // Only log on the app store if the debug setting is enabled in settings
	return NO;
#else
	return YES;
#endif
}
	
+ (BOOL)loggingEnabled {
    /// Remove logging from release mode
    if ([ALLogger isProduction]) {
        return NO;
    }
	// True if...
	return ([ALLogger usingSeverityFiltering]) ||								// Using severity filtering OR							// severity filtering is done in the logWithVerbosity:severity:formatArgs method
	(![ALLogger isProduction] && [ALLogger shouldLogInDebug]) ||			// Debug and logging is enabled in debug OR
	([ALLogger isProduction] && [ALLogger shouldLogInProduction]) ||		// Production and logging is enabled in production OR
	([self userDefaultsOverride]);										// the User Defaults override is set.
}
	
	
+ (void)logWithVerbosity:(ALLoggerVerbosity)verbosity severity:(ALLoggerSeverity)severity formatArgs:(NSArray *)args {
	
	// Bail if verbosity has been set to None
	if (ALLoggerVerbosityNone == verbosity)
	return;
	
	NSString *format = [self formatForVerbosity:verbosity];
	
	if ([ALLogger usingSeverityFiltering]) {
		
		// Bail if it doesn't meet the minimum severity
		if (![ALLogger meetsMinimumSeverity:severity])
		return;
		
		NSString *label = [ALLogger labelForSeverity:severity];
		format = [NSString stringWithFormat:@"[%@]\t%@", label, format];
	}
	
	[ALLogger log:format,
	 [args count] >= 1 ? [args objectAtIndex:0] : nil,
	 [args count] >= 2 ? [args objectAtIndex:1] : nil,
	 [args count] >= 3 ? [args objectAtIndex:2] : nil,
	 [args count] >= 4 ? [args objectAtIndex:3] : nil,
	 [args count] >= 5 ? [args objectAtIndex:4] : nil,
	 [args count] >= 6 ? [args objectAtIndex:5] : nil,
	 [args count] >= 7 ? [args objectAtIndex:6] : nil,
	 [args count] >= 8 ? [args objectAtIndex:7] : nil,
	 [args count] >= 9 ? [args objectAtIndex:8] : nil
	 ];
}

+ (void)log:(NSString *)format, ... {
	
	@try {
		if ([ALLogger loggingEnabled]) {
            if (format != nil) {
                
                va_list args;
                va_start(args, format);
                NSString *logStatement = [[NSString alloc] initWithFormat:format arguments:args];
                va_end(args);
                
                // pass through to NSLog
                NSLog(@"%@", logStatement);
                
                // add to front of logArray (with date) so it is in reverse chronological order
                NSMutableArray *logArray = [self logArray];
                NSString *formattedDate = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
                NSString *retainedLogStatement = [NSString stringWithFormat:@"[%@] %@", formattedDate, logStatement];
                [logArray insertObject:retainedLogStatement atIndex:0];
                
                // pop excess logs
                if ([logArray count] > UA__maxLogsRetained) {
                    [logArray removeObjectsInRange:
                     NSMakeRange(UA__maxLogsRetained, [logArray count] - UA__maxLogsRetained)];
                }
                
            }
        }
    } @catch (...) {}
	
}
	
#pragma mark - User Defaults / NSNotificationCenter
	
+ (void)observeUserDefaultsKey {
	// Get notifications when the user defaults changes.
	// This allows us to cache the [+ userDefaultsKey] bool value so [+ loggingEnabled] will be faster
	[[NSNotificationCenter defaultCenter] addObserver:[self class]
											 selector:@selector(defaultsDidChange:)
												 name:NSUserDefaultsDidChangeNotification
											   object:nil];
	
	// But we also need to set it initially to the value stored on disk
	BOOL override = [[NSUserDefaults standardUserDefaults] boolForKey:[self userDefaultsKey]];
	[self setUserDefaultsOverride:override];
}
	
+ (void)defaultsDidChange:(NSNotification *)notification {
	NSUserDefaults *defaults = [notification object];
	BOOL override = [defaults boolForKey:[self userDefaultsKey]];
	[self setUserDefaultsOverride:override];
}
	
	
+ (NSString *)userDefaultsKey {
	if (!UA__userDefaultsKey)
	UA__userDefaultsKey = ALLogger_LoggingEnabled;
	
	
	return UA__userDefaultsKey;
}

+ (void)setUserDefaultsKey:(NSString *)userDefaultsKey {
    UA__userDefaultsKey = userDefaultsKey;
}

#pragma mark - Log array

+ (NSMutableArray *) logArray {
    static NSMutableArray *logArray = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *logArrayFilepath = [self logArrayFilepath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:logArrayFilepath]) {
            logArray = [[NSMutableArray alloc] initWithContentsOfFile:logArrayFilepath];
        }
        else {
            logArray = [NSMutableArray array];
        }
    });
    return logArray;
}

+ (void) saveLogArray {
    /// Simply return if logging is disabled
    if (![ALLogger loggingEnabled]) {
        return;
    }
    NSMutableArray *logArray = [self logArray];
    NSString *logArrayFilepath = [self logArrayFilepath];
    [logArray writeToFile:logArrayFilepath atomically:YES];
}

+ (NSString *) logArrayFilepath {
    NSArray *folders = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask];
    NSURL *libraryDir = [folders objectAtIndex:0];
    return [libraryDir.path stringByAppendingPathComponent:@"ApplozicLogs.txt"];
}

+ (NSString *) logArrayAsString {
    NSMutableArray *logArray = [self logArray];
    return [logArray componentsJoinedByString:@"\n\n"];
}
	
	
@end
