//
//  ViewController.m
//  netTest
//
//  Created by tqh on 2018/5/4.
//  Copyright © 2018年 tqh. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //全局队列是并发队列没有名字，dispatch_get_global_queue(0, 0)
    
    [self test4];
}

//多请求结束后统一操作
//例：如一个页面多个网络请求后刷新UI
- (void)test1 {
    //模拟并发后统一操作数据
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //请求1
        NSLog(@"Request_1");
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        //模拟网络请求
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            NSLog(@"请求开始");
            sleep(2);
            NSLog(@"请求完成");
            //请求完成信号量+1，信号量为1，通过
            dispatch_semaphore_signal(sema);
        });
        NSLog(@"我是测试");
        //信号量为0，进行等待
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    });
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //请求2
        NSLog(@"Request_2");
    });
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //请求3
        NSLog(@"Request_3");
    });
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        //界面刷新
        NSLog(@"任务均完成，刷新界面");
    });
}

//多请求顺序执行
//例：如第二个请求需要第一个请求的数据来操作
- (void)test2 {
    // 1.任务一：获取用户信息
    NSBlockOperation *operation1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"Request_1");
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            NSLog(@"请求1开始");
            sleep(3);
            NSLog(@"请求1完成");
            //请求完成信号量+1，信号量为1，通过
            dispatch_semaphore_signal(sema);
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }];
    
    // 2.任务二：请求相关数据
    NSBlockOperation *operation2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"Request_2");
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            NSLog(@"请求2开始");
            sleep(2);
            NSLog(@"请求2完成");
            //请求完成信号量+1，信号量为1，通过
            dispatch_semaphore_signal(sema);
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }];
    
    // 3.设置依赖
    [operation2 addDependency:operation1];// 任务二依赖任务一
    
    // 4.创建队列并加入任务
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperations:@[operation2, operation1] waitUntilFinished:NO];
}

//enter leave
- (void)test3 {
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"Request_1");
        sleep(3);
        NSLog(@"Request1完成");
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"Request_2");
        sleep(1);
        NSLog(@"Request2完成");
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"Request_3");
        sleep(2);
        NSLog(@"Request3完成");
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group,  dispatch_get_main_queue(), ^{
        
        NSLog(@"全部完成.%@,name ",[NSThread currentThread]);
    });
}

//栅栏函数
- (void)test4 {
    //同dispatch_queue_create函数生成的concurrent Dispatch Queue队列一起使用
    dispatch_queue_t queue = dispatch_queue_create("12312312", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(queue, ^{
        NSLog(@"----1-----%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----2-----%@", [NSThread currentThread]);
    });
    
    dispatch_barrier_async(queue, ^{
        NSLog(@"----barrier-----%@", [NSThread currentThread]);
    });
    
    dispatch_async(queue, ^{
        
        NSLog(@"----3-----%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----4-----%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----5-----%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"----6-----%@", [NSThread currentThread]);
    });
}

//获取线程的名字
- (void)test5 {
    
    //串行队列DISPATCH_QUEUE_SERIAL
    
    //并行队列
    dispatch_queue_t queue = dispatch_queue_create("a a a",DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSLog(@"1---%@ name = %@",[NSThread currentThread],[[NSThread currentThread]name]);
    });
    dispatch_async(queue, ^{
        NSLog(@"2---%@",[NSThread currentThread]);
    });
}

@end
