#import "ControlRootViewController.h"
#include "CTBattery.h"
#include "CTChargePolicy.h"
#include "CTCPU.h"
#include "CTDisplay.h"
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
@property (nonatomic, strong) UISlider *chargeSlider;
@property (nonatomic, strong) UISwitch *chargeSwitch;
@property (nonatomic, strong) UISegmentedControl *fpsControl;
@property (nonatomic, strong) NSTimer *refreshTimer;
@end

@implementation ControlRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"CONTROL";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshAll)];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
    [self refreshAll];
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(refreshAll) userInfo:nil repeats:YES];
}

- (void)dealloc {
    [self.refreshTimer invalidate];
}

- (void)refreshAll {
    CTBatteryRead(&_battery);
    CTChargePolicyRead(&_chargePolicy);
    CTDisplayRead(&_displayInfo);
    CTCPURead(&_cpuInfo);
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return CTSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case CTSectionBattery: return 8;
        case CTSectionCharge: return 2;
        case CTSectionDisplay: return 2;
        case CTSectionCPU: return 3;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case CTSectionBattery: return @"Battery";
        case CTSectionCharge: return @"Charge Limit";
        case CTSectionDisplay: return @"Display";
        case CTSectionCPU: return @"CPU";
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == CTSectionCharge) {
        return @"Uses Apple's charging preference keys. For hard inflow inhibition, add an SMC backend for CH0C/CH0I on verified devices.";
    }
    if (section == CTSectionCPU) {
        return [NSString stringWithUTF8String:self.cpuInfo.note];
    }
    if (section == CTSectionDisplay) {
        return @"The app stores a preferred cap and can be extended with device-specific IOMobileFramebuffer/CoreDisplay writes after validation.";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.numberOfLines = 1;
    cell.detailTextLabel.text = nil;

    NSString *title = @"";
    NSString *value = @"";
    if (indexPath.section == CTSectionBattery) {
        [self configureBatteryTitle:&title value:&value row:indexPath.row];
    } else if (indexPath.section == CTSectionCharge) {
        [self configureChargeCell:cell row:indexPath.row];
        return cell;
    } else if (indexPath.section == CTSectionDisplay) {
        [self configureDisplayCell:cell row:indexPath.row];
        return cell;
    } else if (indexPath.section == CTSectionCPU) {
        [self configureCPUTitle:&title value:&value row:indexPath.row];
    }

    cell.textLabel.text = title.length ? [NSString stringWithFormat:@"%@  %@", title, value] : value;
    return cell;
}

- (void)configureBatteryTitle:(NSString **)title value:(NSString **)value row:(NSInteger)row {
    switch (row) {
        case 0: *title = @"Percent"; *value = [NSString stringWithFormat:@"%d%%", self.battery.currentCapacityPercent]; break;
        case 1: *title = @"Capacity"; *value = [NSString stringWithFormat:@"%d / %d mAh", self.battery.rawCurrentCapacityMah, self.battery.rawMaxCapacityMah]; break;
        case 2: *title = @"Design"; *value = [NSString stringWithFormat:@"%d mAh", self.battery.designCapacityMah]; break;
        case 3: *title = @"Cycles"; *value = [NSString stringWithFormat:@"%d", self.battery.cycleCount]; break;
        case 4: *title = @"Voltage"; *value = [NSString stringWithFormat:@"%d mV", self.battery.voltageMv]; break;
        case 5: *title = @"Current"; *value = [NSString stringWithFormat:@"%d mA", self.battery.amperageMa]; break;
        case 6: *title = @"Temperature"; *value = [NSString stringWithFormat:@"%.2f C", self.battery.temperatureCentiC / 100.0]; break;
        case 7: *title = @"Charging"; *value = self.battery.isCharging ? @"Yes" : (self.battery.externalConnected ? @"External power" : @"No"); break;
    }
}

- (void)configureCPUTitle:(NSString **)title value:(NSString **)value row:(NSInteger)row {
    switch (row) {
        case 0: *title = @"Current"; *value = [self hzString:self.cpuInfo.currentHz]; break;
        case 1: *title = @"Max"; *value = [self hzString:self.cpuInfo.maxHz]; break;
        case 2: *title = @"Min"; *value = [self hzString:self.cpuInfo.minHz]; break;
    }
}

- (NSString *)hzString:(uint64_t)hz {
    if (hz == 0) return @"Unavailable";
    return [NSString stringWithFormat:@"%.2f GHz", (double)hz / 1000000000.0];
}

- (void)configureChargeCell:(UITableViewCell *)cell row:(NSInteger)row {
    if (row == 0) {
        cell.textLabel.text = @"Enabled";
        UISwitch *sw = [[UISwitch alloc] init];
        sw.on = self.chargePolicy.enabled;
        [sw addTarget:self action:@selector(chargeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        self.chargeSwitch = sw;
        cell.accessoryView = sw;
        return;
    }
    cell.textLabel.text = [NSString stringWithFormat:@"Limit %.0f%%", self.chargePolicy.maxPercent];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 170, 32)];
    slider.minimumValue = 40.0f;
    slider.maximumValue = 100.0f;
    slider.value = self.chargePolicy.maxPercent;
    [slider addTarget:self action:@selector(chargeSliderChanged:) forControlEvents:UIControlEventValueChanged];
    self.chargeSlider = slider;
    cell.accessoryView = slider;
}

- (void)configureDisplayCell:(UITableViewCell *)cell row:(NSInteger)row {
    if (row == 0) {
        cell.textLabel.text = @"Max FPS";
        NSArray *items = @[@"60", @"80", @"90", @"120"];
        UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:items];
        NSInteger selected = [items indexOfObject:[NSString stringWithFormat:@"%d", self.displayInfo.preferredMaxFps]];
        seg.selectedSegmentIndex = selected == NSNotFound ? 0 : selected;
        [seg addTarget:self action:@selector(fpsChanged:) forControlEvents:UIControlEventValueChanged];
        self.fpsControl = seg;
        cell.accessoryView = seg;
        return;
    }
    cell.textLabel.text = self.displayInfo.panelId[0] ? [NSString stringWithFormat:@"Panel  %s", self.displayInfo.panelId] : @"Panel  Unavailable";
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

@end
