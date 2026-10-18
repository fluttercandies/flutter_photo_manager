// Tests for the Foundation-only helpers in PMFileHelper.
//
// darwin/photo_manager/Package.swift depends on the FlutterFramework package,
// which only exists inside a Flutter app build, so these tests cannot be a test
// target of that package. .github/scripts/run_darwin_unit_tests.sh compiles
// them together with PMFileHelper.m into an XCTest bundle and runs it with
// xctest on macOS.

#import <XCTest/XCTest.h>

#import "PMFileHelper.h"

static const NSUInteger kTitleBudget = 40;

static NSString *PMCharacter(UTF32Char codePoint) {
    UTF32Char littleEndian = NSSwapHostIntToLittle(codePoint);
    return [[NSString alloc] initWithBytes:&littleEndian
                                    length:sizeof(littleEndian)
                                  encoding:NSUTF32LittleEndianStringEncoding];
}

static NSString *PMRepeat(NSString *string, NSUInteger count) {
    return [@"" stringByPaddingToLength:string.length * count withString:string startingAtIndex:0];
}

/// A letter followed by 200 combining acute accents: one composed character
/// sequence of 201 UTF-16 code units (the example from the review of #1445).
static NSString *PMOversizedCombiningSequence(void) {
    return [@"a" stringByAppendingString:PMRepeat(PMCharacter(0x0301), 200)];
}

@interface PMFileHelperTests : XCTestCase
@end

@implementation PMFileHelperTests

/// Every result must fit the budget, be a prefix of the sanitised title and
/// end on one of its composed character sequence boundaries.
- (void)assertTitle:(NSString *)result isBoundedPrefixOf:(NSString *)sanitised {
    XCTAssertLessThanOrEqual(result.length, kTitleBudget, @"%@", result);
    // Not -hasPrefix:, which is NO for an empty prefix.
    XCTAssertLessThanOrEqual(result.length, sanitised.length);
    XCTAssertEqualObjects([sanitised substringToIndex:MIN(result.length, sanitised.length)], result,
                          @"not a prefix of %@", sanitised);
    if (result.length < sanitised.length) {
        NSRange next = [sanitised rangeOfComposedCharacterSequenceAtIndex:result.length];
        XCTAssertEqual(next.location, result.length, @"the cut splits a composed character sequence");
    }
}

- (void)testDropsTitleWhoseFirstSequenceExceedsTheBudget {
    NSString *title = PMOversizedCombiningSequence();
    XCTAssertEqual([title rangeOfComposedCharacterSequenceAtIndex:0].length, title.length,
                   @"Foundation no longer treats the letter and its marks as one sequence");

    NSString *result = [PMFileHelper cacheFilenameTitleForTitle:title];

    XCTAssertEqualObjects(result, @"");
    [self assertTitle:result isBoundedPrefixOf:title];
}

- (void)testKeepsTheSequencesBeforeAnOversizedCombiningSequence {
    NSString *title = [@"Holiday " stringByAppendingString:PMOversizedCombiningSequence()];

    NSString *result = [PMFileHelper cacheFilenameTitleForTitle:title];

    XCTAssertEqualObjects(result, @"Holiday ");
    [self assertTitle:result isBoundedPrefixOf:title];
}

- (void)testCutsALongPlainTitleAtTheBudget {
    NSString *title = @"A long caption imported from a social app, with #hashtags and more text";

    NSString *result = [PMFileHelper cacheFilenameTitleForTitle:title];

    XCTAssertEqualObjects(result, [title substringToIndex:kTitleBudget]);
    [self assertTitle:result isBoundedPrefixOf:title];
}

- (void)testDoesNotSplitASurrogatePairAtTheBudget {
    // The emoji takes code units 39 and 40.
    NSString *head = PMRepeat(@"a", 39);
    NSString *title = [[head stringByAppendingString:PMCharacter(0x1F600)] stringByAppendingString:@"tail"];

    NSString *result = [PMFileHelper cacheFilenameTitleForTitle:title];

    XCTAssertEqualObjects(result, head);
    [self assertTitle:result isBoundedPrefixOf:title];
}

- (void)testDoesNotSplitMultiUnitSequencesAtTheBudget {
    NSString *flag = [PMCharacter(0x1F1F9) stringByAppendingString:PMCharacter(0x1F1F7)];
    NSString *family = [@[PMCharacter(0x1F468), PMCharacter(0x1F469), PMCharacter(0x1F467), PMCharacter(0x1F466)]
                        componentsJoinedByString:PMCharacter(0x200D)];
    NSString *toned = [PMCharacter(0x1F44D) stringByAppendingString:PMCharacter(0x1F3FD)];
    NSString *accented = [@"e" stringByAppendingString:PMCharacter(0x0301)];
    // Each sequence starts within the budget and ends on code unit 40, the
    // first one past it.
    for (NSString *sequence in @[flag, family, toned, accented]) {
        NSString *head = PMRepeat(@"a", kTitleBudget - sequence.length + 1);
        NSString *title = [[head stringByAppendingString:sequence] stringByAppendingString:@"tail"];

        NSString *result = [PMFileHelper cacheFilenameTitleForTitle:title];

        XCTAssertEqualObjects(result, head, @"sequence of %lu code units", (unsigned long)sequence.length);
        [self assertTitle:result isBoundedPrefixOf:title];
    }
}

- (void)testKeepsTitlesWithinTheBudgetUnchanged {
    NSArray<NSString *> *titles = @[
        @"IMG_0001",
        PMRepeat(@"b", kTitleBudget),
        [@"Beach " stringByAppendingString:PMCharacter(0x1F3D6)],
        [@"Cafe" stringByAppendingString:PMCharacter(0x0301)],
    ];
    for (NSString *title in titles) {
        XCTAssertEqualObjects([PMFileHelper cacheFilenameTitleForTitle:title], title);
    }
}

- (void)testReplacesPathSeparators {
    XCTAssertEqualObjects([PMFileHelper cacheFilenameTitleForTitle:@"2026/08/26: trip"], @"2026_08_26_ trip");

    NSString *title = [PMRepeat(@"a/", 30) stringByAppendingString:@":"];
    NSString *result = [PMFileHelper cacheFilenameTitleForTitle:title];
    XCTAssertEqualObjects(result, [PMRepeat(@"a_", 30) substringToIndex:kTitleBudget]);
}

- (void)testKeepsAnEmptyTitleEmpty {
    XCTAssertEqualObjects([PMFileHelper cacheFilenameTitleForTitle:@""], @"");
}

/// The title only exists to build a cache filename, so build the longest name
/// makeAssetOutputPath can produce around it and create that file. A name
/// component may hold 255 characters of its decomposed form, which is what
/// Foundation hands to the file system.
- (void)testCacheFilenamesBuiltFromTheTitleCanBeCreated {
    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSError *error = nil;
    XCTAssertTrue([manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error], @"%@", error);
    [self addTeardownBlock:^{
        [NSFileManager.defaultManager removeItemAtPath:directory error:nil];
    }];
    NSURL *source = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"source"]];
    XCTAssertTrue([[NSData data] writeToURL:source options:0 error:&error], @"%@", error);

    // Local identifier with `/` replaced, %f timestamp and the origin marker.
    NSString *prefix = @"ED7AC36B-A150-4C38-BB8C-B6D696F4F2ED_L0_001_1756200000.123456_o_";
    NSArray<NSString *> *titles = @[
        PMOversizedCombiningSequence(),
        [@"Holiday " stringByAppendingString:PMOversizedCombiningSequence()],
        @"A long caption imported from a social app, with #hashtags and more text",
        PMRepeat(PMCharacter(0x1F600), 60),
        // Each code unit decomposes into three (Hangul) or four (Greek) characters.
        PMRepeat(PMCharacter(0xD55C), 60),
        PMRepeat(PMCharacter(0x1F82), 60),
    ];
    for (NSString *title in titles) {
        NSString *name = [[prefix stringByAppendingString:[PMFileHelper cacheFilenameTitleForTitle:title]]
                          stringByAppendingString:@".jpeg.pmcache"];
        NSURL *destination = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:name]];

        BOOL copied = [manager copyItemAtURL:source toURL:destination error:&error];

        XCTAssertTrue(copied, @"%lu code units: %@", (unsigned long)name.length, error);
    }
}

@end
