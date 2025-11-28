import WidgetKit
import SwiftUI
import Intents

/// 위젯 데이터 모델
struct WidgetData {
    let userId: String
    let totalPosts: Int
    let totalLikes: Int
    let totalComments: Int
    let recentPost: RecentPost?
}

struct RecentPost {
    let id: String
    let title: String
    let previewText: String
    let createdAt: Date
}

/// 위젯 엔트리
struct HomeWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetData?
}

/// 위젯 Provider - 데이터 로드 및 타임라인 생성
struct HomeWidgetProvider: TimelineProvider {
    typealias Entry = HomeWidgetEntry
    
    func placeholder(in context: Context) -> HomeWidgetEntry {
        HomeWidgetEntry(
            date: Date(),
            data: WidgetData(
                userId: "user123",
                totalPosts: 10,
                totalLikes: 50,
                totalComments: 20,
                recentPost: RecentPost(
                    id: "post1",
                    title: "새 게시물",
                    previewText: "게시물 미리보기 텍스트...",
                    createdAt: Date()
                )
            )
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HomeWidgetEntry) -> Void) {
        let entry = HomeWidgetEntry(
            date: Date(),
            data: loadWidgetData()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeWidgetEntry>) -> Void) {
        let currentDate = Date()
        let entry = HomeWidgetEntry(
            date: currentDate,
            data: loadWidgetData()
        )
        
        // 다음 업데이트 시간 (15분 후)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    /// UserDefaults에서 위젯 데이터 로드
    private func loadWidgetData() -> WidgetData? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.example.communityapp") else {
            return nil
        }
        
        guard let userId = sharedDefaults.string(forKey: "flutter.widget_data_userId"),
              !userId.isEmpty else {
            return nil
        }
        
        let totalPosts = sharedDefaults.integer(forKey: "flutter.widget_data_totalPostsCount")
        let totalLikes = sharedDefaults.integer(forKey: "flutter.widget_data_totalLikesCount")
        let totalComments = sharedDefaults.integer(forKey: "flutter.widget_data_totalCommentsCount")
        
        let recentPostId = sharedDefaults.string(forKey: "flutter.widget_data_recentPostId")
        let recentPostTitle = sharedDefaults.string(forKey: "flutter.widget_data_recentPostTitle") ?? ""
        let recentPostPreview = sharedDefaults.string(forKey: "flutter.widget_data_recentPostPreview") ?? ""
        
        var recentPost: RecentPost? = nil
        if let postId = recentPostId, !postId.isEmpty {
            recentPost = RecentPost(
                id: postId,
                title: recentPostTitle,
                previewText: recentPostPreview,
                createdAt: Date()
            )
        }
        
        return WidgetData(
            userId: userId,
            totalPosts: totalPosts,
            totalLikes: totalLikes,
            totalComments: totalComments,
            recentPost: recentPost
        )
    }
}

/// 위젯 뷰
struct HomeWidgetEntryView: View {
    var entry: HomeWidgetProvider.Entry
    
    var body: some View {
        if let data = entry.data {
            VStack(spacing: 12) {
                // 제목
                Text("Lion SNS")
                    .font(.headline)
                    .fontWeight(.bold)
                
                // 통계 정보
                HStack(spacing: 20) {
                    StatisticItem(label: "게시글", value: data.totalPosts)
                    StatisticItem(label: "좋아요", value: data.totalLikes)
                    StatisticItem(label: "댓글", value: data.totalComments)
                }
                
                // 최근 게시물
                if let post = data.recentPost {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("최근 게시물")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(post.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        if !post.previewText.isEmpty {
                            Text(post.previewText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .containerBackground(.fill.secondary, for: .widget)
        } else {
            VStack {
                Text("데이터 없음")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

/// 통계 아이템 뷰
struct StatisticItem: View {
    let label: String
    let value: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// 위젯 메인 구조
struct HomeWidget: Widget {
    let kind: String = "HomeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeWidgetProvider()) { entry in
            HomeWidgetEntryView(entry: entry)
                .containerBackground(.fill.secondary, for: .widget)
        }
        .configurationDisplayName("Lion SNS 통계")
        .description("내 게시글, 좋아요, 댓글 수와 최근 게시물을 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// 위젯 Bundle
@main
struct HomeWidgetBundle: WidgetBundle {
    var body: some Widget {
        HomeWidget()
    }
}

/// 위젯 미리보기
#Preview(as: .systemSmall) {
    HomeWidget()
} timeline: {
    HomeWidgetEntry(
        date: Date(),
        data: WidgetData(
            userId: "user123",
            totalPosts: 10,
            totalLikes: 50,
            totalComments: 20,
            recentPost: RecentPost(
                id: "post1",
                title: "새 게시물",
                previewText: "게시물 미리보기 텍스트입니다...",
                createdAt: Date()
            )
        )
    )
}

