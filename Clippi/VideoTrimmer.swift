// https://gist.github.com/acj/b8c5f8eafe0605a38692
import AVFoundation
import Foundation
import UIKit

class VideoTrimmer {
    
    typealias TrimPoints = [(CMTime, CMTime)]
    private static var trimError: Error {
        return NSError(domain: "com.nidhik.clippi", code: -1, userInfo: nil) as Error
    }
    
    func verifyPresetForAsset(preset: String, asset: AVAsset) -> Bool {
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
        let filteredPresets = compatiblePresets.filter { $0 == preset }
        return filteredPresets.count > 0 || preset == AVAssetExportPresetPassthrough
    }
    
    func removeFileAtURLIfExists(url: URL) {
        
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            try fileManager.removeItem(at: url)
        }
        catch let error {
            print("TrimVideo - Couldn't remove existing destination file: \(String(describing: error))")
        }
    }
    
    func trimVideo(sourceURL: URL, destinationURL: URL,
                   trimPoints: TrimPoints,
                   completion: @escaping (Result<URL, Error>) -> Void) {
        
        guard sourceURL.isFileURL, destinationURL.isFileURL else {
            completion(.failure(VideoTrimmer.trimError))
            return }
        
        let options = [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ]
        let asset = AVURLAsset(url: sourceURL, options: options)
        let preferredPreset = AVAssetExportPresetPassthrough
        
        if  verifyPresetForAsset(preset: preferredPreset, asset: asset) {
            
            let composition = AVMutableComposition()
            guard let videoCompTrack = composition.addMutableTrack(withMediaType: .video,
                                                                   preferredTrackID: CMPersistentTrackID()),
                let audioCompTrack = composition.addMutableTrack(withMediaType: .audio,
                                                                 preferredTrackID: CMPersistentTrackID()),
                let assetVideoTrack: AVAssetTrack = asset.tracks(withMediaType: .video).first,
                let assetAudioTrack: AVAssetTrack = asset.tracks(withMediaType: .audio).first else {
                    completion(.failure(VideoTrimmer.trimError))
            return }

            videoCompTrack.preferredTransform = assetVideoTrack.preferredTransform
            
            var accumulatedTime = CMTime.zero
            for (startTimeForCurrentSlice, endTimeForCurrentSlice) in trimPoints {
                let durationOfCurrentSlice = CMTimeSubtract(endTimeForCurrentSlice, startTimeForCurrentSlice)
                let timeRangeForCurrentSlice = CMTimeRangeMake(start: startTimeForCurrentSlice,
                                                               duration: durationOfCurrentSlice)
                
                do {
                    try videoCompTrack.insertTimeRange(timeRangeForCurrentSlice,
                                                       of: assetVideoTrack,
                                                       at: accumulatedTime)
                    try audioCompTrack.insertTimeRange(timeRangeForCurrentSlice,
                                                       of: assetAudioTrack,
                                                       at: accumulatedTime)
                    accumulatedTime = CMTimeAdd(accumulatedTime, durationOfCurrentSlice)
                }
                catch let compError {
                    print("TrimVideo: error during composition: \(compError)")
                    completion(.failure(compError))
                }
            }
            
            guard let exportSession = AVAssetExportSession(asset: composition, presetName: preferredPreset) else {
                completion(.failure(VideoTrimmer.trimError))
                return }
            
            exportSession.outputURL = destinationURL
            exportSession.outputFileType = AVFileType.mp4
            exportSession.shouldOptimizeForNetworkUse = true
            
            removeFileAtURLIfExists(url: destinationURL as URL)
            
            exportSession.exportAsynchronously {
                
                switch exportSession.status {
                case .completed:
                    completion(.success(destinationURL))
                case .failed:
                    completion(.failure(exportSession.error!))
                    print("failed \(exportSession.error.debugDescription)")
                case .cancelled:
                    completion(.failure(exportSession.error!))
                    print("cancelled \(exportSession.error.debugDescription)")
                default:
                    if let err = exportSession.error {
                        completion(.failure(err))
                    }
                }
            }
        }
        else {
            print("TrimVideo - Could not find a suitable export preset for the input video")
            completion(.failure(VideoTrimmer.trimError))
        }
    }
}
