//
//  witness_calc.m
//  rapidsnark_Example
//
//  Created by Yaroslav Moria on 26.07.2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

#import "witness_calc.h"

#import <Foundation/Foundation.h>


void* test(const char *inputs, const void *graph_data, const size_t graph_data_len) {
    void* witness;
    size_t witness_len;

    const gw_status_t status;

    int result = gw_calc_witness(inputs, graph_data, graph_data_len, &witness, &witness_len, &status);

    if (result == 0) {
        return witness;
    } else {
        NSLog(@"Witness calc error: %s", status.error_msg);
        return nil;
    }
}


void* testJubJub(const char *inputs, const void *graph_data, const size_t graph_data_len) {
    char* signature = "415b8523177be6153b1e05161d471caa40ad1dc5b8ad3ed810b4b3dfca30d0b65c9446fff76af58343ec2502c0637fe9b2f519023c22adcbe98f2f33fa98ab0f";

    char* packed = pack_signature(signature);
    
    NSData *dataData = [NSData dataWithBytes:packed length:sizeof(packed)];
    NSLog(@"data = %@", dataData);
    
    return nil;
}
