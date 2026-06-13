#import "CTLocalization.h"

static NSString *const CTLanguageDefaultsKey = @"CTLanguages.Current";

CTLanguage CTCurrentLanguage(void) {
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:CTLanguageDefaultsKey];
    if ([value isEqualToString:@"en"]) return CTLanguageEnglish;
    return CTLanguageSimplifiedChinese;
}

void CTSetCurrentLanguage(CTLanguage language) {
    NSString *value = language == CTLanguageEnglish ? @"en" : @"zh-Hans";
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:CTLanguageDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

NSString *CTL(NSString *key) {
    static NSDictionary *zh = nil;
    static NSDictionary *en = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        zh = @{
            @"app.title": @"厘工",
            @"language.zh": @"中文",
            @"language.en": @"English",
            @"section.battery": @"电池",
            @"section.charge": @"充电限制",
            @"section.display": @"显示与锁帧",
            @"section.cpu": @"CPU 与温控",
            @"row.percent": @"电量",
            @"row.capacity": @"容量",
            @"row.design": @"设计容量",
            @"row.cycles": @"循环次数",
            @"row.voltage": @"电压",
            @"row.current": @"电流",
            @"row.temperature": @"温度",
            @"row.charging": @"充电状态",
            @"row.enabled": @"启用",
            @"row.limit": @"上限",
            @"row.maxfps": @"最大刷新率",
            @"row.unlock48": @"解除 48FPS 限制",
            @"row.panel": @"面板",
            @"row.cpu.current": @"当前频率",
            @"row.cpu.max": @"最大频率",
            @"row.cpu.min": @"最小频率",
            @"row.thermal": @"禁用系统温控",
            @"yes": @"是",
            @"no": @"否",
            @"external.power": @"外接电源",
            @"unavailable": @"不可用",
            @"footer.battery": @"从 AppleSmartBattery/IOPMPowerSource 读取原始电池数据。",
            @"footer.charge": @"写入 Apple 充电策略偏好；硬件级断充需设备验证后再启用 SMC 后端。",
            @"footer.display": @"解除 48FPS 会写入显示偏好并尝试通知显示服务；是否生效取决于设备与系统版本。",
            @"footer.cpu": @"iOS 通常不暴露 CPU 频率 sysctl；温控开关会修改 launchd 禁用表，需重启生效。",
            @"thermal.warning": @"禁用温控可能导致过热、降寿命或异常关机。",
            @"reboot.required": @"更改已写入，通常需要重启后生效。"
        };
        en = @{
            @"app.title": @"LiGong",
            @"language.zh": @"中文",
            @"language.en": @"English",
            @"section.battery": @"Battery",
            @"section.charge": @"Charge Limit",
            @"section.display": @"Display / FPS",
            @"section.cpu": @"CPU / Thermal",
            @"row.percent": @"Percent",
            @"row.capacity": @"Capacity",
            @"row.design": @"Design",
            @"row.cycles": @"Cycles",
            @"row.voltage": @"Voltage",
            @"row.current": @"Current",
            @"row.temperature": @"Temperature",
            @"row.charging": @"Charging",
            @"row.enabled": @"Enabled",
            @"row.limit": @"Limit",
            @"row.maxfps": @"Max FPS",
            @"row.unlock48": @"Unlock 48FPS cap",
            @"row.panel": @"Panel",
            @"row.cpu.current": @"Current Freq",
            @"row.cpu.max": @"Max Freq",
            @"row.cpu.min": @"Min Freq",
            @"row.thermal": @"Disable thermal daemon",
            @"yes": @"Yes",
            @"no": @"No",
            @"external.power": @"External power",
            @"unavailable": @"Unavailable",
            @"footer.battery": @"Reads raw battery data from AppleSmartBattery/IOPMPowerSource.",
            @"footer.charge": @"Writes Apple's charging policy preferences; hard charge inhibition needs a verified SMC backend.",
            @"footer.display": @"Unlocking 48FPS writes display preferences and posts display notifications; effect depends on device and iOS build.",
            @"footer.cpu": @"iOS often hides CPU frequency sysctls; thermal changes edit launchd's disabled table and usually need a reboot.",
            @"thermal.warning": @"Disabling thermal protection can cause overheating, battery wear, or shutdowns.",
            @"reboot.required": @"Change written. A reboot is usually required."
        };
    });
    NSString *value = (CTCurrentLanguage() == CTLanguageEnglish ? en : zh)[key];
    return value ?: key;
}
