//
//  ViewController.m
//  MapKit
//
//  Created by Daniel Fairbanks on 5/20/14.
//  Copyright (c) 2014 Fairbanksdan. All rights reserved.
//

#import "ViewController.h"
@import MapKit;
@import AVFoundation;
#define CODE_FELLOWS_COORDINATE CLLocationCoordinate2DMake(47.623548, -122.336212)

@interface ViewController () <UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) MKLocalSearchResponse *searchResponse;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	

    self.locationManager = [[CLLocationManager alloc] init];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(CODE_FELLOWS_COORDINATE, 1000, 1000);
    [_mapView setRegion:region animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Search Bar Delegate

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    [request setRegion:self.mapView.region];
    [request setNaturalLanguageQuery:searchBar.text];
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

        if (error) {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
        if (!response.mapItems.count) {
            NSLog(@"No Results Found");
            return;
        }
        self.searchResponse = response;
        [self.searchDisplayController.searchResultsTableView reloadData];
        
    }];
}

#pragma mark - Table View Delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResponse.mapItems.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        
    }
    MKMapItem *item = self.searchResponse.mapItems[indexPath.row];
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = item.placemark.addressDictionary[@"Street"];
    NSLog(@"%@", item.placemark.addressDictionary);
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchDisplayController setActive:NO animated:YES];
     MKMapItem *item = self.searchResponse.mapItems[indexPath.row];
    [self.mapView addAnnotation:item.placemark];
    [self drawRouteForItem:item];
}

-(void)drawRouteForItem:(MKMapItem *)item
{
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source = [MKMapItem mapItemForCurrentLocation];
    request.destination = item;
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error Calculating Directions %@", error);
        } else {
            [self showRoute:response];
        }
    }];
}

-(void)showRoute:(MKDirectionsResponse *)response
{
    for (MKRoute *route in response.routes) {
        AVSpeechSynthesizer *speech = [AVSpeechSynthesizer new];
        [self.mapView addOverlay:route.polyline level:MKOverlayLevelAboveRoads];
        for (MKRouteStep *step in route.steps) {
            NSLog(@"%@", step.instructions);
            [speech speakUtterance:[AVSpeechUtterance speechUtteranceWithString:step.instructions]];
        }
    }
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    renderer.strokeColor = [UIColor redColor];
    renderer.lineWidth = 5.0;
    
    return renderer;
}

- (IBAction)currentLocation:(id)sender {
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    CLLocationCoordinate2D location = [[[_mapView userLocation] location] coordinate];
    NSLog(@"Location found from Map: %f %f",location.latitude,location.longitude);
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 1000, 1000);
    
    [_mapView setRegion:region animated:YES];
}




@end
