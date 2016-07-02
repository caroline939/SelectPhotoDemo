//
//  selectMainVC.m
//  selectPIC
//
//  Created by colorful-ios on 15/11/23.
//  Copyright © 2015年 7Color. All rights reserved.
//

#import "selectMainVC.h"

#import <Photos/Photos.h>

#import "SelectMainCell.h"

#import "ShowIMGVC.h"

#import "ShowIMGModel.h"


@interface selectMainVC ()<UITableViewDataSource,UITableViewDelegate,PHPhotoLibraryChangeObserver>
@property (nonatomic,strong)UITableView *tableView;

@property (nonatomic,strong)NSMutableArray *groupNames;

@end
static selectMainVC *singleView = nil;

@implementation selectMainVC


//单例控制器？？  有个疑问，为嘛一定要把控制器写成单例？？仅仅是下一个控制器传值？？在我看来，通知不就行了。单例控制器在内存中不会清除缓存。。这对性能好嘛？？

+ (selectMainVC *)shareSelectMainVC{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleView = [[selectMainVC alloc]init];
    });
    return singleView;
}


- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title = @"相册";
    
    
    //加载相册信息
    [self loadIMGData];
    
    //判断访问相册权限
    if ([PHPhotoLibrary authorizationStatus]) {
        
        
        //设置tableView
        [self createTableViewWithHiddenNav:NO];

    }else{
    
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(refreshNotification:) userInfo:nil repeats:YES];
        
//        [NSRunLoop currentRunLoop] addTimer:timer forMode:
    }
    
    
}
- (void)refreshNotification:(NSTimer*)timer{
    if ([PHPhotoLibrary authorizationStatus]) {
        
        [self createTableViewWithHiddenNav:YES];
        
        [self loadIMGData];
        
        [timer invalidate];
        timer = nil;
        
    }
    
    
}

//- (void)photoLibraryDidChange:(PHChange *)changeInstance{
//
////    if ([PHPhotoLibrary authorizationStatus]) {
////        if (!self.groupNames.count) {
////            [self createTableViewWithHiddenNav:YES];
////            
////            [self loadIMGData];
////
////            
//////            dispatch_async(dispatch_get_main_queue(), ^{
//////                [_tableView reloadData];
//////            });
////        }
////
////    }
//    
//}

- (void)loadIMGData{
    


    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
    
    //创建一个相册数组.存放PHassetCollection
    self.groupNames = [NSMutableArray arrayWithCapacity:0];
    
    // 列出所有相册智能相册
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    // 列出所有用户创建的相册
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
    
    
    //遍历相册
    [smartAlbums enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        PHAssetCollection *assetCollection = obj;
        NSString *tempStr = assetCollection.localizedTitle;
        
        /**
         All Photos:        所有照片
         Bursts:            连拍快照
         Favorites:         收藏
         Selfies:           自拍
         Screenshots:       屏幕快照
         Recently Added:    最近添加
         */
        if ([tempStr isEqualToString:@"All Photos"]||[tempStr isEqualToString:@"Favorites"]||[tempStr isEqualToString:@"Screenshots"]||[tempStr isEqualToString:@"Selfies"]||[tempStr isEqualToString:@"Recently Added"]||[tempStr isEqualToString:@"Bursts"]||[tempStr isEqualToString:@"Recently Deleted"]||[tempStr isEqualToString:@"Camera Roll"]) {
            
            [self.groupNames addObject:obj];
            
        }
        
    }];
    

    
    [topLevelUserCollections enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self.groupNames addObject:obj];
        
    }];
    
    
    
    //再次对相册数组进行遍历。。目的为了，去除相册中， 照片为空的相册。。。。仅仅保留有照片的相册
    for (NSInteger i =0; i < self.groupNames.count; i++) {
        
        PHAssetCollection *assetCollection = self.groupNames[i];
        
        PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
        
        NSLog(@"sub album title is %@, count is %ld", assetCollection.localizedTitle, assetsFetchResult.count);
        
        if (!(assetsFetchResult.count >0)) {
            
            [self.groupNames removeObject:assetCollection];
            i--;
            
        }
        
  
    }

    
    //刷新tableview
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableView reloadData];
    });
}


#pragma mark     ---------就目前思路还是很清晰的.



- (void)createTableViewWithHiddenNav:(BOOL)nav{
    
    self.tableView = [[UITableView alloc]initWithFrame:self.view.frame
                                                 style:UITableViewStylePlain];
    if (nav) {
        _tableView.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
        
    }else{
           _tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height );
    }
    
    self.tableView.dataSource       = self;
    
    self.tableView.delegate         = self;
    
    self.tableView.tableFooterView  = [[UIView alloc]init];
    
    [self.view addSubview:self.tableView];

}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.groupNames.count;
}
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    SelectMainCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Select"];
    
    if (!cell) {
        
        cell = [[SelectMainCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Select"];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50.0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    SelectMainCell *cells = (SelectMainCell*)cell;
    
    
    //self.groupNames 数组里装着PHAssetCollection  对象。
    PHAssetCollection *assetCollection = self.groupNames[indexPath.row];
    
    //便利 PHAssetCollection 对象里的PHAsset 对象
    PHFetchResult   *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
    
    if (assetsFetchResult.count > 0) {
        
        PHImageManager *imageManager = [[PHImageManager alloc] init];
        
        
        //传入最后一个PHAsset 对象，获取到的图像当作相册的封面.
        
        [imageManager requestImageForAsset:assetsFetchResult[assetsFetchResult.count-1]
                                targetSize:CGSizeMake(50, 50)
                               contentMode:PHImageContentModeAspectFill
                                   options:nil
                             resultHandler:^(UIImage *result, NSDictionary *info) {
                                 
                                 /**
                                  All Photos:        所有照片
                                  Bursts:            连拍快照
                                  Favorites:         收藏
                                  Selfies:           自拍
                                  Screenshots:       屏幕快照
                                  Recently Added:    最近添加
                                  */
                                 
                                 NSString *titleStr = nil;
                                 if ([assetCollection.localizedTitle isEqualToString:@"All Photos"]) {
                                     titleStr = @"所有照片";
                                 }else if ([assetCollection.localizedTitle isEqualToString:@"Bursts"]){
                                     titleStr = @"连拍快照";
                                 }else if ([assetCollection.localizedTitle isEqualToString:@"Favorites"]){
                                     titleStr = @"收藏";
                                 }else if ([assetCollection.localizedTitle isEqualToString:@"Selfies"]){
                                     titleStr = @"自拍";
                                 }else if ([assetCollection.localizedTitle isEqualToString:@"Screenshots"]){
                                     titleStr = @"屏幕快照";
                                 }else if ([assetCollection.localizedTitle isEqualToString:@"Recently Added"]){
                                     titleStr = @"最近添加";
                                 }else if ([assetCollection.localizedTitle isEqualToString:@"Recently Deleted"]){
                                     titleStr = @"最近删除";
                                 }else if ([assetCollection.localizedTitle isEqualToString:@"Camera Roll"]){
                                     titleStr = @"所有照片";
                                 }else{
                                     titleStr = assetCollection.localizedTitle;
                                 }
                                 
                                 
                                 //刷新cell
                                 [cells configCellWithHeadIMG:result andTitle:titleStr andIMGCount:[NSString stringWithFormat:@"%lu",(unsigned long)assetsFetchResult.count]];
                                 
                             }];
    }

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
       //取出相册
        PHAssetCollection *assetCollection = self.groupNames[indexPath.row];
    
       //创建匹配参数
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
    
       //设置参数的条件
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
     //根据条件便利出照片结果
        PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
        
        NSLog(@"sub album title is %@, count is %ld", assetCollection.localizedTitle, (unsigned long)assetsFetchResult.count);
    
    //创建数组用于装上次选取照片的数组中 ShowIMGModel 模型
        NSMutableArray *mutaArray = [NSMutableArray arrayWithCapacity:0];
    
    //创建相册控制器
    
        ShowIMGVC *showView = [[ShowIMGVC alloc] init];
    
       NSLog(@"%@",self.selecIMG);
    
    
    //self.selecIMG 已经选择的图片model数组
        for (ShowIMGModel *model in self.selecIMG) {
            
            [mutaArray addObject:model.phAsset];
        }
    
    //上次已经选取的照片所构建的ShowIMGModel
        showView.selectedModel = mutaArray;
    //相册中所有的照片 所组成的 PHFetchResult
        showView.assetsFetchResult = assetsFetchResult;
    
        SelectMainCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        showView.title =cell.titleLabel.text;
        [self.navigationController pushViewController:showView animated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
