//
//  EverMainWindow.m
//  Ever FilterGenerator
//
//  Created by Simon CORSIN on 5/14/13.
//  Copyright (c) 2013 com.ever. All rights reserved.
//

#import <objc/runtime.h>
#import <GPUImage/GPUImage.h>
#import "EverMainWindow.h"
#import "EverFilterCellView.h"
#import "LevelsPanel.h"
#import "EverFilterExporter.h"

@implementation EverMainWindow

@synthesize filters;
@synthesize source;

- (void) awakeFromNib {
    [super awakeFromNib];
}

-(void)buildThatThing {
    _pipelineEnabled = YES;
    self.imageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
    self.filters = [[NSMutableArray alloc] init];
    self.availableFilters = [[NSMutableDictionary alloc] init];
    
    [self addFilter:[[EverBrightnessFilter alloc] init]];
    [self addFilter:[[EverExposureFilter alloc] init]];
    [self addFilter:[[EverGammaFilter alloc] init]];
    [self addFilter:[[EverContrastFilter alloc] init]];
    [self addFilter:[[EverGaussianBlurFilter alloc] init]];
    [self addFilter:[[EverSaturationFilter alloc] init]];
    [self addFilter:[[EverSharpFilter alloc] init]];
    [self addFilter:[[EverPixellateFilter alloc] init]];
    [self addFilter:[[EverLevelsFilter alloc] init]];
    [self addFilter:[[EverMultiplyBlendFilter alloc] init]];
    [self addFilter:[[EverOverlayBlendFilter alloc] init]];
    [self addFilter:[[EverAddBlendFilter alloc] init]];
    [self addFilter:[[EverSubtractBlendFilter alloc] init]];
    [self addFilter:[[EverColorBurnBlendFilter alloc] init]];
    [self addFilter:[[EverScreenBlendFilter alloc] init]];
    [self addFilter:[[EverAlphaBlendFilter alloc] init]];
    [self addFilter:[[EverNormalBlendFilter alloc] init]];
    [self addFilter:[[EverLinearBlendFilter alloc] init]];
    [self addFilter:[[EverImageLookupFilter alloc] init]];
    [self addFilter:[[EverExclusionFilter alloc] init]];
    
    self.filterTableView.dataSource = self;
    self.filterTableView.delegate = self;
    [self setOpenedFile:nil];
}

-(void)addFilter:(EverFilter*)everFilter {
    [self.availableFilters setObject:everFilter forKey:everFilter.name];
}

-(void)disconnectPipeline {
    if (self.source != nil) {
        [self.source removeAllTargets];
    }
    
    for (EverFilter * everFilter in self.filters) {
        [everFilter.filter removeAllTargets];
    }
}

-(void)attachFilterToPipeline:(NSString*)filterName {
    EverFilter * filter = [self.availableFilters objectForKey:filterName];
    
    if (filter != nil) {
        filter = [filter newInstance];
        filter.manipulator = self;
        [self.filters addObject:filter];
        [self rebuildPipeline];
        
        NSIndexSet * set = [[NSIndexSet alloc] initWithIndex:self.filters.count];
        [self.filterTableView insertRowsAtIndexes:set withAnimation:NSTableViewAnimationSlideLeft];
    } else {
        NSLog(@"Filter %@ not found", filterName);
    }
}

- (void) removeFilter:(EverFilter*)filter {
    NSUInteger index = [self.filters indexOfObject:filter];
    
    [self disconnectPipeline];
    [self.filterTableView beginUpdates];
    [self.filterTableView removeRowsAtIndexes:[[NSIndexSet alloc]initWithIndex:index] withAnimation:NSTableViewAnimationSlideRight];
    [self.filters removeObjectAtIndex:index];
    [self.filterTableView endUpdates];
        
    [self rebuildPipeline];
}

-(void)showParameter:(EverFilter*)filter {
    [filter showParameterWindow];
}

-(void)rebuildPipeline {
    [self disconnectPipeline];
    
    if (self.source != nil) {
        CGSize processingSize = self.source.outputImageSize;
        GPUImageOutput * lastFilter = self.source;
            
        if (_pipelineEnabled) {
            for (EverFilter * everFilter in self.filters) {
                if (everFilter.enabled) {
                    [everFilter.filter forceProcessingAtSize:processingSize];
                    [everFilter willRebuildPipeline];
                    [lastFilter addTarget:everFilter.filter atTextureLocation:0];
                    lastFilter = everFilter.filter;
                }
            }
        }
            
        [lastFilter addTarget:self.imageView];
        
        if (_pipelineEnabled) {
            for (EverFilter * everFilter in self.filters) {
                if (everFilter.enabled) {
                    [everFilter didRebuildPipeline];
                }
            }
            
        }
        
        [self processImage];
    }
}

-(void)clearPipeline {
    [self disconnectPipeline];
    [self.filters removeAllObjects];
}

-(void)newDocument:(id)sender {
    [self clearPipeline];
    [self setOpenedFile:nil];
    [self.filterTableView reloadData];
    [self rebuildPipeline];
}

-(void)addFilterBrightness:(id)sender {
    [self attachFilterToPipeline:@"Brightness"];
}

- (void)addFilterExposure:(id)sender {
    [self attachFilterToPipeline:@"Exposure"];
}

- (void) addFilterGamma:(id)sender {
    [self attachFilterToPipeline:@"Gamma"];
}

- (void) addFilterContrast:(id)sender {
    [self attachFilterToPipeline:@"Contrast"];
}

- (void) addFilterGaussian:(id)sender {
    [self attachFilterToPipeline:@"Gaussian blur"];
}

- (void) addFilterSaturation:(id)sender {
    [self attachFilterToPipeline:@"Saturation"];
}

- (void) addFilterSharpen:(id)sender {
    [self attachFilterToPipeline:@"Sharpen"];
}

- (void) addFilterPixellate:(id)sender {
    [self attachFilterToPipeline:@"Pixellate"];
}

- (void) addFilterLevel:(id)sender {
    [self attachFilterToPipeline:@"Levels"];
}

- (void) addFilterOverlay:(id)sender {
    [self attachFilterToPipeline:@"Overlay blend"];
}

- (void) addFilterMultiply:(id)sender {
    [self attachFilterToPipeline:@"Multiply blend"];
}

- (void) addFilterAdd:(id)sender {
    [self attachFilterToPipeline:@"Add blend"];
}

- (void) addFilterSubstract:(id)sender {
    [self attachFilterToPipeline:@"Substract blend"];
}

- (void) addFilterColorBurn:(id)sender {
    [self attachFilterToPipeline:@"Color burn blend"];
}

- (void) addFilterScreen:(id)sender {
    [self attachFilterToPipeline:@"Screen blend"];
}

- (void) addFilterAlpha:(id)sender {
    [self attachFilterToPipeline:@"Alpha blend"];
}

- (void) addFilterNormal:(id)sender {
    [self attachFilterToPipeline:@"Normal blend"];
}

- (void) addFilterLinear:(id)sender {
    [self attachFilterToPipeline:@"Linear burn blend"];
}

- (void)addFilterExclusion:(id) sender {
    [self attachFilterToPipeline:@"Exclusion blend"];
}

- (void) addFilterLookup:(id) sender {
    [self attachFilterToPipeline:@"Lookup image"];
}

- (void) scanTargets {
    [self scanElement:self.source indent:0];
}

- (void) scanElement:(GPUImageOutput*)output indent:(NSInteger)indent {
    for (NSInteger i = 0; i < indent; i++) {
        printf("    ");
    }
    
    printf("%s\n", class_getName([output class]));
    
    for (id current in output.targets) {
        if ([current isKindOfClass:[GPUImageOutput class]]) {
            [self scanElement:current indent:indent + 1];
        } else {
            
        }
    }
}

-(void)processImage {
    if (self.source != nil) {
        
        for (EverFilter * everFilter in self.filters) {
            if (everFilter.enabled) {
                [everFilter willProcessImage];
            }
        }
        
        //[self scanTargets];
        [self.source processImage];
    }
}

-(void)openDocument:(id)sender {
    NSOpenPanel * panel = [NSOpenPanel openPanel];
    
    [panel setAllowedFileTypes:[[NSArray alloc] initWithObjects:@"efl", nil]];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL * document = [[panel URLs] objectAtIndex:0];
            
            [self setOpenedFile:document];
            NSMutableArray * array = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfURL:document]];
                        
            if (array != nil) {
                for (EverFilter * filter in array) {
                    NSLog(@"Filter: %@", filter.name);
                    filter.manipulator = self;
                }
                
                [self clearPipeline];
                self.filters = array;
                
                [self.filterTableView reloadData];
                
                [self rebuildPipeline];
                [self rebuildPipeline]; // Hack must find out why this is necessary
                NSLog(@"Loaded!");
            } else {
                NSLog(@"Failed to load");
            }
        }
    }];
}

- (void) openImage:(id)sender {
    NSOpenPanel * panel = [NSOpenPanel openPanel];
    
    [panel setAllowedFileTypes:[[NSArray alloc] initWithObjects:@"jpg", @"jpeg", @"png", nil]];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL * document = [[panel URLs] objectAtIndex:0];
            
            NSImage * image = [[NSImage alloc] initWithContentsOfURL:document];
            
            if ([image isValid]) {
                GPUImagePicture * picture = [[GPUImagePicture alloc] initWithImage:image];
                
                [self disconnectPipeline];
                
                self.source = picture;
                
                [self rebuildPipeline];
                [self rebuildPipeline]; // HACK Must find out why this is necessary
            } else {
                NSLog(@"Picture is not valid");
            }
        }
    }];
}

- (void) setOpenedFile:(NSURL*)file {
    self.file = file;
    
    if (file != nil) {
        self.title = [@"Ever FilterGenerator - " stringByAppendingString:[file lastPathComponent]];
        [[NSFileManager defaultManager] changeCurrentDirectoryPath:[file.path stringByDeletingLastPathComponent]];
    } else {
        self.title = @"Ever FilterGenerator - New Document";
    }
}

- (void) saveDocument:(id)sender {
    if (self.file == nil) {
        [self saveDocumentTo:self];
    } else {
        [self saveDocumentToURL:self.file];
    }
}

- (void) saveDocumentToURL:(NSURL*)url {
    [self setOpenedFile:url];
    NSData* artistData = [NSKeyedArchiver archivedDataWithRootObject:self.filters];
    
    if (artistData != nil) {
        if ([artistData writeToURL:url atomically:YES]) {
            NSLog(@"Success");
        } else {
            NSLog(@"Failed to save");
        }
        
    } else {
        NSLog(@"Failed to archive");
    }
}

- (void) saveDocumentTo:(id)sender {
    NSSavePanel * panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:@"My gorgeous filter"];
    [panel setAllowedFileTypes:[[NSArray alloc] initWithObjects:@"efl", nil]];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [self saveDocumentToURL:[panel URL]];
        }
    }];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView*)tableView {
    return self.filters.count;
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    EverFilterCellView * filterCell = [tableView makeViewWithIdentifier:@"EverFilterCellView" owner:self];
    
    if (filterCell != nil) {
        [filterCell buildCell:[self.filters objectAtIndex:row]];
        filterCell.delegate = self;
    } else {
        NSLog(@"Dat is noule");
    }
    
    return filterCell;
}

- (void) editPressed:(EverFilterCellView *)cell {
    [cell.filter showParameterWindow];
}

- (void) deletePressed:(EverFilterCellView *)cell {
    [self removeFilter:cell.filter];
}

- (void) bypassBoxChanged:(EverFilterCellView *)cell {
    cell.filter.enabled = cell.checkbox.state;
    [self rebuildPipeline];
}

- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    return YES;
}



- (NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    return NSDragOperationEvery;
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    NSLog(@"Asking for a pasteboard");
    return nil;
}

- (IBAction)leftButtonPressed:(id)sender {
    NSInteger row = [self.filterTableView selectedRow];
    if (row != -1) {
        if (row > 0) {
            NSInteger othRow = row - 1;
            id selected = [self.filters objectAtIndex:row];
            id previous = [self.filters objectAtIndex:othRow];
            
            [self.filters replaceObjectAtIndex:othRow withObject:selected];
            [self.filters replaceObjectAtIndex:row withObject:previous];
            [self.filterTableView moveRowAtIndex:othRow toIndex:row];
            [self rebuildPipeline];
        }
    }
}

- (IBAction)rightButtonPressed:(id)sender {
    NSInteger row = [self.filterTableView selectedRow];
    if (row != -1) {
        if (row < [self.filters count] - 1) {
            NSInteger othRow = row + 1;
            id selected = [self.filters objectAtIndex:row];
            id previous = [self.filters objectAtIndex:othRow];
            
            [self.filters replaceObjectAtIndex:othRow withObject:selected];
            [self.filters replaceObjectAtIndex:row withObject:previous];
            [self.filterTableView moveRowAtIndex:othRow toIndex:row];
            [self rebuildPipeline];
        }
    }
}

- (void) exportDocument:(id)sender {
    NSSavePanel * panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:@"EverFilter"];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [EverFilterExporter exportFilters:self.filters outputFile:[panel URL]];
        }
    }];
}

- (IBAction)switchButtonPressed:(id)sender {
    _pipelineEnabled = self.switchButton.state;
    [self rebuildPipeline];
}

- (void) forceRefresh:(id)sender {
    [self.filterTableView reloadData];
    [self rebuildPipeline];
}

@end
