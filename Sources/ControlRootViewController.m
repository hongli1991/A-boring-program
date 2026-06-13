#import "ControlRootViewController.h"
#import "CTLocalization.h"
#include "CTBattery.h"
#include "CTChargePolicy.h"
#include "CTCPU.h"
#include "CTDisplay.h"
#include "CTRoot.h"
#include "CTThermal.h"
#include <math.h>

typedef NS_ENUM(NSInteger, CTSection) {
    CTSectionBattery,
    CTSectionCharge,
    CTSectionDisplay,
    CTSectionCPU,
    CTSectionCount
};

@interface ControlRootViewController ()
@property (nonatomic) CTBatteryInfo battery;
@property (nonatomic) CTChargePolicy chargePolicy;
@property (nonatomic) CTDisplayInfo displayInfo;
@property (nonatomic) CTCPUInfo cpuInfo;
@property (nonatomic) BOOL thermalDisabled;
@property (nonatomic, strong) UISwitch *chargeSwitch;
@property (nonatomic, strong) NSTimer *refreshTimer;
@end

@implementation ControlRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UISegmentedControl *language = [[UISegmentedControl alloc] initWithItems:@[CTL(@"language.zh"), CTL(@"language.en")]];
    language.selectedSegmentIndex = CTCurrentLanguage() == CTLanguageEnglish ? 1 : 0;
    [language addTarget:self action:@selector(languageChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:language];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshAll)];
    [self applyLanguage];
    [self refreshAll];
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(refreshAll) userInfo:nil repeats:YES];
}

- (void)dealloc {
    [self.refreshTimer invalidate];
}

- (void)applyLanguage {
    self.title = CTL(@"app.title");
}

- (void)refreshAll {
    CTBatteryRead(&_battery);
    CTChargePolicyRead(&_chargePolicy);
    CTDisplayRead(&_displayInfo);
    CTCPURead(&_cpuInfo);
    self.thermalDisabled = CTThermalDaemonDisabled();
    [self.tableView reloadData];
}

- (UITableViewCell *)newCell {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.numberOfLines = 1;
    cell.detailTextLabel.numberOfLines = 2;
    cell.detailTextLabel.textColor = UIColor.secondaryLabelColor;
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return CTSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case CTSectionBattery: return 8;
        case CTSectionCharge: return 2;
        case CTSectionDisplay: return 3;
        case CTSectionCPU: return 6;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case CTSectionBattery: return CTL(@"section.battery");
        case CTSectionCharge: return CTL(@"section.charge");
        case CTSectionDisplay: return CTL(@"section.display");
        case CTSectionCPU: return CTL(@"section.cpu");
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case CTSectionBattery: return CTL(@"footer.battery");
        case CTSectionCharge: return CTL(@"footer.charge");
        case CTSectionDisplay: return CTL(@"footer.display");
        case CTSectionCPU: return CTL(@"footer.cpu");
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self newCell];
    if (indexPath.section == CTSectionBattery) [self configureBatteryCell:cell row:indexPath.row];
    if (indexPath.section == CTSectionCharge) [self configureChargeCell:cell row:indexPath.row];
    if (indexPath.section == CTSectionDisplay) [self configureDisplayCell:cell row:indexPath.row];
    if (indexPath.section == CTSectionCPU) [self configureCPUCell:cell row:indexPath.row];
    return cell;
}

- (void)setCell:(UITableViewCell *)cell title:(NSString *)title value:(NSString *)value detail:(NSString *)detail {
    cell.textLabel.text = value.length ? [NSString stringWithFormat:@"%@  %@", title, value] : title;
    cell.detailTextLabel.text = detail;
}

- (void)configureBatteryCell:(UITableViewCell *)cell row:(NSInteger)row {
    switch (row) {
        case 0: [self setCell:cell title:CTL(@"row.percent") value:[NSString stringWithFormat:@"%d%%", self.battery.currentCapacityPercent] detail:@"UI reported battery percentage."]; break;
        case 1: [self setCell:cell title:CTL(@"row.capacity") value:[NSString stringWithFormat:@"%d / %d mAh", self.battery.rawCurrentCapacityMah, self.battery.rawMaxCapacityMah] detail:@"Raw current and full charge capacity."]; break;
        case 2: [self setCell:cell title:CTL(@"row.design") value:[NSString stringWithFormat:@"%d mAh", self.battery.designCapacityMah] detail:@"Original design capacity reported by the battery."]; break;
        case 3: [self setCell:cell title:CTL(@"row.cycles") value:[NSString stringWithFormat:@"%d", self.battery.cycleCount] detail:@"Charge cycle count stored by the gas gauge."]; break;
        case 4: [self setCell:cell title:CTL(@"row.voltage") value:[NSString stringWithFormat:@"%d mV", self.battery.voltageMv] detail:@"Instant battery voltage."]; break;
        case 5: [self setCell:cell title:CTL(@"row.current") value:[NSString stringWithFormat:@"%d mA", self.battery.amperageMa] detail:@"Positive or negative battery current."]; break;
        case 6: [self setCell:cell title:CTL(@"row.temperature") value:[NSString stringWithFormat:@"%.2f C", self.battery.temperatureCentiC / 100.0] detail:@"Battery pack temperature sensor."]; break;
        case 7: {
            NSString *state = self.battery.isCharging ? CTL(@"yes") : (self.battery.externalConnected ? CTL(@"external.power") : CTL(@"no"));
            [self setCell:cell title:CTL(@"row.charging") value:state detail:@"Charging and adapter connection state."];
            break;
        }
    }
}

- (void)configureChargeCell:(UITableViewCell *)cell row:(NSInteger)row {
    if (row == 0) {
        [self setCell:cell title:CTL(@"row.enabled") value:nil detail:@"Enables Apple charging-limit preference behavior."];
        UISwitch *sw = [[UISwitch alloc] init];
        sw.on = self.chargePolicy.enabled;
        [sw addTarget:self action:@selector(chargeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        self.chargeSwitch = sw;
        cell.accessoryView = sw;
        return;
    }
    [self setCell:cell title:[NSString stringWithFormat:@"%@ %.0f%%", CTL(@"row.limit"), self.chargePolicy.maxPercent] value:nil detail:@"Target percentage where charging should stop."];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 170, 32)];
    slider.minimumValue = 40.0f;
    slider.maximumValue = 100.0f;
    slider.value = self.chargePolicy.maxPercent;
    [slider addTarget:self action:@selector(chargeSliderChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = slider;
}

- (void)configureDisplayCell:(UITableViewCell *)cell row:(NSInteger)row {
    if (row == 0) {
        [self setCell:cell title:CTL(@"row.maxfps") value:nil detail:@"Preferred display cap written to app display preferences."];
        NSArray *items = @[@"60", @"80", @"90", @"120"];
        UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:items];
        NSInteger selected = [items indexOfObject:[NSString stringWithFormat:@"%d", self.displayInfo.preferredMaxFps]];
        seg.selectedSegmentIndex = selected == NSNotFound ? 0 : selected;
        [seg addTarget:self action:@selector(fpsChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = seg;
        return;
    }
    if (row == 1) {
        [self setCell:cell title:CTL(@"row.unlock48") value:nil detail:@"Writes display policy hints intended to bypass thermal 48FPS caps."];
        UISwitch *sw = [[UISwitch alloc] init];
        sw.on = self.displayInfo.unlock48Enabled;
        [sw addTarget:self action:@selector(unlock48Changed:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
        return;
    }
    NSString *panel = self.displayInfo.panelId[0] ? [NSString stringWithUTF8String:self.displayInfo.panelId] : CTL(@"unavailable");
    [self setCell:cell title:CTL(@"row.panel") value:panel detail:@"Panel identifier from IOMobileFramebuffer when available."];
}

- (void)configureCPUCell:(UITableViewCell *)cell row:(NSInteger)row {
    switch (row) {
        case 0: [self setCell:cell title:CTL(@"row.cpu.current") value:[self hzString:self.cpuInfo.currentHz] detail:@"Often hidden by iOS on real devices."]; break;
        case 1: [self setCell:cell title:CTL(@"row.cpu.max") value:[self hzString:self.cpuInfo.maxHz] detail:@"Public sysctl value if the kernel exposes it."]; break;
        case 2: [self setCell:cell title:CTL(@"row.cpu.min") value:[self hzString:self.cpuInfo.minHz] detail:@"Public sysctl value if the kernel exposes it."]; break;
        case 3: [self setCell:cell title:@"Machine" value:[NSString stringWithUTF8String:self.cpuInfo.machine] detail:@"Hardware model identifier."]; break;
        case 4: [self setCell:cell title:@"Cores" value:[NSString stringWithFormat:@"%d / %d", self.cpuInfo.activeCores, self.cpuInfo.logicalCores] detail:@"Online and configured logical cores."]; break;
        case 5: {
            [self setCell:cell title:CTL(@"row.thermal") value:nil detail:CTL(@"thermal.warning")];
            UISwitch *sw = [[UISwitch alloc] init];
            sw.on = self.thermalDisabled;
            [sw addTarget:self action:@selector(thermalChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
            break;
        }
    }
}

- (NSString *)hzString:(uint64_t)hz {
    if (hz == 0) return CTL(@"unavailable");
    return [NSString stringWithFormat:@"%.2f GHz", (double)hz / 1000000000.0];
}

- (void)languageChanged:(UISegmentedControl *)sender {
    CTSetCurrentLanguage(sender.selectedSegmentIndex == 1 ? CTLanguageEnglish : CTLanguageSimplifiedChinese);
    [self applyLanguage];
    [self refreshAll];
}

- (void)chargeSwitchChanged:(UISwitch *)sender {
    CTChargePolicy policy = self.chargePolicy;
    policy.enabled = sender.on;
    policy.stopWhenPluggedIn = true;
    self.chargePolicy = policy;
    CTChargePolicyWrite(&policy);
    [self refreshAll];
}

- (void)chargeSliderChanged:(UISlider *)sender {
    CTChargePolicy policy = self.chargePolicy;
    policy.maxPercent = roundf(sender.value);
    policy.enabled = self.chargeSwitch.on;
    policy.stopWhenPluggedIn = true;
    self.chargePolicy = policy;
    CTChargePolicyWrite(&policy);
    [self refreshAll];
}

- (void)fpsChanged:(UISegmentedControl *)sender {
    NSString *text = [sender titleForSegmentAtIndex:sender.selectedSegmentIndex];
    CTDisplaySetPreferredMaxFPS(text.intValue);
    [self refreshAll];
}

- (void)unlock48Changed:(UISwitch *)sender {
    CTDisplaySetUnlock48FPS(sender.on);
    [self refreshAll];
}

- (void)thermalChanged:(UISwitch *)sender {
    const char *args[] = {"thermal", sender.on ? "off" : "on", NULL};
    CTStatus status = CTRootRunHelper(args);
    if (status != CTStatusOK) {
        CTThermalSetDaemonDisabled(sender.on);
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:CTL(@"row.thermal") message:CTL(@"reboot.required") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    [self refreshAll];
}

@end
