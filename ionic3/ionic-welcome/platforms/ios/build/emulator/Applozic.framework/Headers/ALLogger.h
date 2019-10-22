//
//  ALLogger.h
//
//  Created by Matt Coneybeare on 09/1/13.
//  Copyright (c) 2013 Urban Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	ALLoggerVerbosityNone = 0,
	ALLoggerVerbosityPlain,
	ALLoggerVerbosityBasic,
	ALLoggerVerbosityFull
} ALLoggerVerbosity;

typedef enum {
	ALLoggerSeverityUnset = 0,		// Unset means it is not factored in on the decision to log, defaulting to the production vs debug and user overrides.
	ALLoggerSeverityDebug,			// Lowest log level
	ALLoggerSeverityInfo,
	ALLoggerSeverityWarn,
	ALLoggerSeverityError,
	ALLoggerSeverityFatal			// Highest log level
} ALLoggerSeverity;


#define ALSLogFull( s, f, ... )	[ALLogger logWithVerbosity:ALLoggerVerbosityFull\
												  severity:s\
												formatArgs:@[\
															self,\
															[[NSString stringWithUTF8String:__FILE__] lastPathComponent],\
															[NSNumber numberWithInt:__LINE__],\
															NSStringFromSelector(_cmd),\
															[NSString stringWithFormat:(f), ##__VA_ARGS__]\
															]\
								]

#define ALSLogBasic( s, f, ... ) [ALLogger logWithVerbosity:ALLoggerVerbosityBasic\
												   severity:s\
												 formatArgs:@[\
															 [[NSString stringWithUTF8String:__FILE__] lastPathComponent],\
															 [NSNumber numberWithInt:__LINE__],\
															 [NSString stringWithFormat:(f), ##__VA_ARGS__]\
															 ]\
								 ]

#define ALSLogPlain( s, f, ... ) [ALLogger logWithVerbosity:ALLoggerVerbosityPlain\
												   severity:s\
												 formatArgs:@[\
															 [NSString stringWithFormat:(f), ##__VA_ARGS__]\
															]\
								 ]

#define ALLogFull( format, ... )			ALSLogFull( ALLoggerSeverityUnset, format, ##__VA_ARGS__ )
#define ALLogBasic( format, ... )			ALSLogBasic( ALLoggerSeverityUnset, format, ##__VA_ARGS__ )
#define ALLogPlain( format, ... )			ALSLogPlain( ALLoggerSeverityUnset, format, ##__VA_ARGS__ )

#define ALLog( format, ... )				ALLogBasic( format, ##__VA_ARGS__ )
#define ALSLog( severity, format, ... )		ALSLogBasic( severity, format, ##__VA_ARGS__ )

#ifdef ALLogGER_SWIZZLE_NSLOG
#define NSLog( s, ... )		ALLog( s, ##__VA_ARGS__ )
#endif

// This is just convenience
#define NSStringFromBool(b) (b ? @"YES" : @"NO")

static NSString * const ALLogger_LoggingEnabled = @"ALLogger_LoggingEnabled";	// This is the default NSUserDefaults key

@interface ALLogger : NSObject
	
	
+ (NSString *)formatForVerbosity:(ALLoggerVerbosity)verbosity;	// Returns the format string for the verbosity. See [+ initialize] for defaults
+ (void)setFormat:(NSString *)format							// Overrides the default formats for verbosities.
	 forVerbosity:(ALLoggerVerbosity)verbosity;
+ (void)resetDefaultLogFormats;									// Resets the formats back to ALLogger defaults
	
+ (void)setMinimumSeverity:(ALLoggerSeverity)severity;
+ (ALLoggerSeverity)minimumSeverity;							// Defaults to ALLoggerSeverityUnset (not used in determining whether or not to log)
+ (BOOL)usingSeverityFiltering;									// Yes if minimumSeverity has been set.
+ (BOOL)meetsMinimumSeverity:(ALLoggerSeverity)severity;		// Yes if severity is greater than or equal to minimumSeverity
	
+ (BOOL)isProduction;											// Returns YES when DEBUG is not present in the Preprocessor Macros
+ (BOOL)shouldLogInProduction;									// Default is NO.
+ (BOOL)shouldLogInDebug;										// Default is YES.
+ (BOOL)userDefaultsOverride;									// Default is NO. Cached BOOL of the userDefaultsKey
+ (void)setShouldLogInProduction:(BOOL)shouldLogInProduction;
+ (void)setShouldLogInDebug:(BOOL)shouldLogInDebug;
+ (void)setUserDefaultsOverride:(BOOL)userDefaultsOverride;
+ (BOOL)loggingEnabled;											// returns true if (not production and shouldLogInDebug) OR (production build and shouldLogInProduction) or (userDefaultsOverride == YES)
	
+ (NSString *)userDefaultsKey;									// Default key is ALLogger_LoggingEnabled
+ (void)setUserDefaultsKey:(NSString *)userDefaultsKey;
	
+ (void)log:(NSString *)format, ...;							// Logs a format, and variables for the format.
	
+ (void)logWithVerbosity:(ALLoggerVerbosity)verbosity			// Logs a preset format based on the vspecified verbosity, and variables for the format.
				severity:(ALLoggerSeverity)severity
			  formatArgs:(NSArray *)args;

+ (NSMutableArray *) logArray;									// gets singleton instance of logArray - from disk, or new
+ (void) saveLogArray;											// use inside applicationWillTerminate: for continuous logging
+ (NSString *) logArrayFilepath;
+ (NSString *) logArrayAsString;								// convenience method / migration from -applicationLog

@end
