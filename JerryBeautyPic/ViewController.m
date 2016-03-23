//
//  ViewController.m
//  JerryBeautyPic
//
//  Created by Jerry on 16/3/13.
//  Copyright © 2016年 Jerry. All rights reserved.
//

#import "ViewController.h"
#import "BmobQuery.h"
#import "UIColor+Hex.h"
#import "BigImageViewController.h"
#import "ImageBlockModel.h"
#import "InfoImageView.h"

#import "Header.h"

#import "AMTumblrHud.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

//列表
@property (weak, nonatomic) IBOutlet UITableView *myTableView;

@property (strong,nonatomic) NSMutableArray *imageBlockModelArray;

@property (assign,nonatomic) CGRect screenRect;

@property (assign,nonatomic) NSUInteger currentIndex;
//被选中的图片
@property (strong,nonatomic) UIImage *selectedImage;
//被选中的图片名称
@property (strong,nonatomic) NSString *selectedImageName;

@property (strong,nonatomic) AMTumblrHud *tumblrHUD;

//进入收藏按钮
@property (strong,nonatomic) UIButton *enterFavorites;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.currentIndex = 0;
    
    //加载初始数据
    [self initLoadImageData];
    //初始化变量
    [self viewSetup];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

#pragma mark - 初始化界面及变量
- (void)viewSetup
{
    self.myTableView.delegate = self;
    self.myTableView.dataSource = self;
    //去掉tableView上面的空白
    self.automaticallyAdjustsScrollViewInsets = false;
    
    self.screenRect = [[UIScreen mainScreen] bounds];
    
    //添加收藏进入按钮
    [self addEnterFavoriteListButton];
}

#pragma mark 添加收藏进入按钮
- (void)addEnterFavoriteListButton
{
    self.enterFavorites = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.enterFavorites setBackgroundImage:[UIImage imageNamed:@"folder_bookmark"] forState:UIControlStateNormal];
    self.enterFavorites.frame = CGRectMake(0, 0, 22, 22);
    [self.enterFavorites addTarget:self action:@selector(enterFavoritesList) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:self.enterFavorites];
    self.navigationItem.rightBarButtonItem = item;
}

- (void)enterFavoritesList
{
    NSLog(@"进入收藏列表");
}

#pragma mark 从服务器加载图片信息
- (void)loadImageInfoFromServer
{
    NSLog(@"start fetch image info from server");
    BmobQuery *bombQuery = [BmobQuery queryWithClassName:@"picture"];
    bombQuery.limit = 3;
    bombQuery.skip = [self.imageBlockModelArray count];
    [bombQuery orderByDescending:@"createdAt"];
    [bombQuery findObjectsInBackgroundWithBlock:^(NSArray *array, NSError *error) {
        if ([array count] > 0) {
            for (BmobObject *obj in array) {
                //
                ImageBlockModel *imageBlock = [[ImageBlockModel alloc] init];
                
                //获得图片
                NSString *urlTemp = [obj objectForKey:@"urlstring"];
                NSString *imageURLStr = [urlTemp stringByRemovingPercentEncoding];
                
                //获得图片名
                NSString *imageName = [imageURLStr lastPathComponent];
                imageBlock.imageName = imageName;
                
                //读取图片数据
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURLStr]]];
                imageBlock.image = image;
                
                //获取更新时间
                NSString *updateDateStr = [obj objectForKey:@"createdAt"];
                updateDateStr = [updateDateStr substringWithRange:NSMakeRange(0, 10)];
                NSLog(@"update time : %@",updateDateStr);
                imageBlock.updateDateStr = updateDateStr;
                
                NSMutableArray *tagsArray = [[NSMutableArray alloc] init];
                //获取tag
                NSString *tag1Str = [obj objectForKey:@"tag1"];
                if (tag1Str != NULL) {
                    NSLog(@"tag1Str : %@",tag1Str);
                    [tagsArray addObject:tag1Str];
                }
                NSString *tag2Str = [obj objectForKey:@"tag2"];
                if (tag2Str != NULL) {
                    NSLog(@"tag2Str : %@",tag2Str);
                    [tagsArray addObject:tag2Str];
                }
                NSString *tag3Str = [obj objectForKey:@"tag3"];
                if (tag3Str != NULL) {
                    NSLog(@"tag3Str : %@",tag3Str);
                    [tagsArray addObject:tag3Str];
                }
                imageBlock.tagsArray = tagsArray;
                
                [self.imageBlockModelArray addObject:imageBlock];
            }
            
            if (self.myTableView) {
                [self.myTableView reloadData];
            }

            if (self.tumblrHUD) {
                [self.tumblrHUD removeFromSuperview];
            }
        }else{
            NSLog(@"没有更多了");
        }
    }];
}

#pragma mark 加载初始数据
- (void)initLoadImageData
{
    self.imageBlockModelArray = [[NSMutableArray alloc] init];
    //显示网络加载动画
    self.tumblrHUD = [[AMTumblrHud alloc] initWithFrame:CGRectMake((CGFloat) ((self.view.frame.size.width - 55) * 0.5),
                                                                           (CGFloat) ((self.view.frame.size.height - 20) * 0.5), 55, 20)];
    self.tumblrHUD.hudColor = UIColorFromRGB(0xF1F2F3);//[UIColor magentaColor];
    [self.view addSubview:self.tumblrHUD];
    
    [self.tumblrHUD showAnimated:YES];
    
    [self loadImageInfoFromServer];
}

#pragma mark 异步加载图片调用
- (void)loadMoreImageInBackground
{
    NSLog(@"开始偷偷加载了 。。。 ");
    NSOperationQueue *operatinQueue = [[NSOperationQueue alloc] init];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(loadImage) object:nil];
    [operatinQueue addOperation:operation];
}

#pragma mark 加载图片
- (void)loadImage
{
    [self loadImageInfoFromServer];
}

#pragma mark - TableView Delegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.imageBlockModelArray.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ImageBlockModel *model = (ImageBlockModel *)[self.imageBlockModelArray objectAtIndex:indexPath.row];
    UIImage *image = model.image;
    CGFloat imageHeight = image.size.height;
    CGFloat imageWidth = image.size.width;
    
    //ImageView的宽度
    CGFloat imageViewWidth = tableView.frame.size.width - 40;
    //计算imageView的高度
    CGFloat imageViewHeight = imageViewWidth * (imageHeight/imageWidth);

    return imageViewHeight + 90;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableViewCell forIndexPath:indexPath];
    
    //解决tableview cell重用导致显示数据出错问题
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableViewCell];
    }
    else{
        //删除数据出错的子视图(动态添加的tag视图)
        UIView *tagsView = [cell viewWithTag:4];
        while ([tagsView.subviews lastObject] != nil) {
            [[tagsView.subviews lastObject] removeFromSuperview];
        }
    }
    
    InfoImageView *imageView = [cell viewWithTag:1];
    
    ImageBlockModel *imageBlock = self.imageBlockModelArray[indexPath.row];
    
    imageView.image = imageBlock.image;
    imageView.imageName = imageBlock.imageName;
    
    //图片添加点击事件
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageClicked:)];
    [imageView addGestureRecognizer:tapGestureRecognizer];
    imageView.userInteractionEnabled = YES;
    
    //设置图片下方区域
    UIView *subTitleView = [cell viewWithTag:2];
    subTitleView.layer.borderWidth = 1;
    subTitleView.layer.borderColor = [[UIColor colorWithHexString:@"#d6dbec"] CGColor];//线的颜色
    
    //更新日期
    UILabel *updateDate = [cell viewWithTag:3];
    updateDate.text = imageBlock.updateDateStr;
    
    //tag
    UIView *tagsView = [cell viewWithTag:4];
    CGFloat tagWidth = 60;
    if ([imageBlock.tagsArray count] > 0) {
        for (int i = 0; i < [imageBlock.tagsArray count]; i ++) {
            //tag 图片
            UIImage *tagImage = [UIImage imageNamed:@"tag"];
            UIImageView *tagImageView = [[UIImageView alloc] initWithImage:tagImage];
            CGRect tagImageFrame = CGRectMake(5 + (i * tagWidth), 15, 20, 20);
            tagImageView.frame = tagImageFrame;
            
            //tag 文字
            NSString *tagOrigin = imageBlock.tagsArray[i];
            NSString *tagContent = nil;
            if ([tagOrigin isEqualToString:TAG_BEAUTY]) {
                tagContent = @"美女";
            }else if ([tagOrigin isEqualToString:TAG_LEG]){
                tagContent = @"美腿";
            }else if ([tagOrigin isEqualToString:TAG_SWIM_SUIT]){
                tagContent = @"泳衣";
            }else if ([tagOrigin isEqualToString:TAG_TIGHT]){
                tagContent = @"紧身";
            }else if ([tagOrigin isEqualToString:TAG_ASS]){
                tagContent = @"美臀";
            }else if ([tagOrigin isEqualToString:TAG_SPORT]){
                tagContent = @"运动";
            }
            
            UILabel *tagLabel = [[UILabel alloc] init];
            tagLabel.text = tagContent;
            [tagLabel setTextColor:[UIColor grayColor]];
            CGRect tagLabelFrame = CGRectMake(tagImageFrame.origin.x + tagImageFrame.size.width,15, 40, 20);
            tagLabel.frame = tagLabelFrame;
            
            [tagsView addSubview:tagImageView];
            [tagsView addSubview:tagLabel];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath ... ");
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //设置当前显示的是倒数第几张图片时，开始从后台加载新图片
    if (([self.imageBlockModelArray count] - indexPath.row) < leftPicNumber) {
        [self loadMoreImageInBackground];
    }
}

#pragma mark - 点击事件
- (void)imageClicked:(UITapGestureRecognizer *) gestureRecognizer
{
    //图片被点击
    InfoImageView *imageView = (InfoImageView *)gestureRecognizer.view;
    self.selectedImage = imageView.image;
    self.selectedImageName = imageView.imageName;
    
    //跳转到大图页面
    [self performSegueWithIdentifier:@"showBig" sender:self];
}

#pragma mark - 跳转处理
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    //判断所选图片在数组中的位置
    
    
    BigImageViewController *bigImageViewController = segue.destinationViewController;
    NSLog(@"准备跳转");
    bigImageViewController.image = self.selectedImage;
    bigImageViewController.imageName = self.selectedImageName;
}

@end
