//
//  AWSConfig.swift
//  Pawse
//
//  AWS S3 Configuration
//

import Foundation

struct AWSConfig {
    // MARK: - S3 Configuration - UPDATE THESE VALUES
    static let region = "us-east-1" // Your actual AWS region
    static let bucketName = "pawse-bucket" // Your actual bucket name
    
    // MARK: - S3 URL Construction
    static func getS3URL(for s3Key: String) -> URL? {
        return URL(string: "https://\(bucketName).s3.\(region).amazonaws.com/\(s3Key)")
    }
}