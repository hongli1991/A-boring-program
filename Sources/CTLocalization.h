#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CTLanguage) {
    CTLanguageSimplifiedChinese = 0,
    CTLanguageEnglish = 1
};

CTLanguage CTCurrentLanguage(void);
void CTSetCurrentLanguage(CTLanguage language);
NSString *CTL(NSString *key);
