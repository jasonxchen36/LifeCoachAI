//
//  InsightsView.swift
//  LifeCoachAI
//
//  Created for LifeCoach AI MVP
//

import SwiftUI
import CoreData
import Charts
import HealthKit

struct InsightsView: View {
    // MARK: - Environment & State
    
    /// Core Data managed object context
    @Environment(\.managedObjectContext) private var viewContext
    
    /// Access to environment objects
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @EnvironmentObject private var mlManager: MLManager
    @EnvironmentObject private var userProfileManager: UserProfileManager
    @EnvironmentObject private var storeManager: StoreManager
    
    /// View state
    @State private var selectedTimeframe: TimeframeOption = .week
    @State private var selectedMetric: HealthMetricType = .steps
    @State private var showingDetailInsight: Insight? = nil
    @State private var isLoading = true
    @State private var showFilters = false
    @State private var selectedInsightCategory: InsightCategory = .all
    
    // MARK: - Computed Properties
    
    /// Health metrics data for selected timeframe
    private var healthMetricsData: [HealthMetric] {
        return healthKitManager.getHealthMetrics(
            for: selectedMetric,
            timeframe: selectedTimeframe.rawValue
        )
    }
    
    /// Daily average for selected metric
    private var dailyAverage: Double {
        if healthMetricsData.isEmpty {
            return 0
        }
        
        let sum = healthMetricsData.reduce(0) { $0 + $1.value }
        return sum / Double(healthMetricsData.count)
    }
    
    /// Weekly trend (up, down, or stable)
    private var weeklyTrend: TrendDirection {
        guard healthMetricsData.count > 7 else { return .stable }
        
        let recentData = Array(healthMetricsData.suffix(7))
        let previousData = Array(healthMetricsData.dropLast(7).suffix(7))
        
        guard !recentData.isEmpty && !previousData.isEmpty else { return .stable }
        
        let recentAvg = recentData.reduce(0) { $0 + $1.value } / Double(recentData.count)
        let previousAvg = previousData.reduce(0) { $0 + $1.value } / Double(previousData.count)
        
        let percentChange = ((recentAvg - previousAvg) / previousAvg) * 100
        
        if percentChange > 5 {
            return .up
        } else if percentChange < -5 {
            return .down
        } else {
            return .stable
        }
    }
    
    /// AI-generated insights
    private var insights: [Insight] {
        var allInsights = mlManager.getInsights()
        
        // Filter by category if not "All"
        if selectedInsightCategory != .all {
            allInsights = allInsights.filter { $0.category == selectedInsightCategory }
        }
        
        return allInsights
    }
    
    /// Correlation insights between metrics
    private var correlationInsights: [CorrelationInsight] {
        return mlManager.getCorrelationInsights()
    }
    
    /// Streak data for selected metric
    private var streakData: StreakInfo {
        return healthKitManager.getStreakInfo(for: selectedMetric)
    }
    
    /// Progress towards goals related to selected metric
    private var relatedGoals: [Goal] {
        return userProfileManager.goals.filter { goal in
            goal.isRelatedToHealthMetric(selectedMetric) && !goal.isCompleted
        }
    }
    
    /// Weekly summary data
    private var weeklySummary: [HealthMetricSummary] {
        var summaries: [HealthMetricSummary] = []
        
        for metricType in HealthMetricType.allCases {
            let metrics = healthKitManager.getHealthMetrics(
                for: metricType,
                timeframe: "week"
            )
            
            if !metrics.isEmpty {
                let total = metrics.reduce(0) { $0 + $1.value }
                let average = total / Double(metrics.count)
                let max = metrics.map { $0.value }.max() ?? 0
                
                summaries.append(HealthMetricSummary(
                    type: metricType,
                    total: total,
                    average: average,
                    max: max
                ))
            }
        }
        
        return summaries
    }
    
    // MARK: - Helper Methods
    
    /// Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Format value based on metric type
    private func formatValue(_ value: Double, for metricType: HealthMetricType) -> String {
        switch metricType {
        case .steps:
            return "\(Int(value))"
        case .activeEnergy:
            return "\(Int(value)) kcal"
        case .heartRate:
            return "\(Int(value)) bpm"
        case .sleepHours:
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            return "\(hours)h \(minutes)m"
        case .weight:
            return String(format: "%.1f kg", value)
        case .mindfulMinutes:
            return "\(Int(value)) min"
        case .standHours:
            return "\(Int(value)) hrs"
        case .workouts:
            return "\(Int(value))"
        }
    }
    
    /// Get color for trend direction
    private func colorForTrend(_ trend: TrendDirection, metricType: HealthMetricType) -> Color {
        // For some metrics like resting heart rate, down is good
        let invertedMetrics: [HealthMetricType] = [.heartRate]
        
        if invertedMetrics.contains(metricType) {
            switch trend {
            case .up:
                return .red
            case .down:
                return .green
            case .stable:
                return .yellow
            }
        } else {
            switch trend {
            case .up:
                return .green
            case .down:
                return .red
            case .stable:
                return .yellow
            }
        }
    }
    
    /// Get icon for metric type
    private func iconForMetric(_ metricType: HealthMetricType) -> String {
        switch metricType {
        case .steps:
            return "figure.walk"
        case .activeEnergy:
            return "flame"
        case .heartRate:
            return "heart"
        case .sleepHours:
            return "bed.double"
        case .weight:
            return "scalemass"
        case .mindfulMinutes:
            return "brain.head.profile"
        case .standHours:
            return "figure.stand"
        case .workouts:
            return "figure.run"
        }
    }
    
    /// Calculate percentage change between two values
    private func percentageChange(from oldValue: Double, to newValue: Double) -> Double {
        guard oldValue != 0 else { return 0 }
        return ((newValue - oldValue) / oldValue) * 100
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Metric selector and timeframe
                metricSelectorHeader
                
                // Main chart
                metricChartCard
                
                // Summary stats
                metricSummaryCard
                
                // AI-generated insights
                insightsSection
                
                // Weekly summary
                weeklySummarySection
                
                // Correlation insights
                correlationSection
                
                // Related goals
                if !relatedGoals.isEmpty {
                    relatedGoalsSection
                }
                
                // Premium features teaser (if not premium)
                if !storeManager.isPremium {
                    premiumFeaturesTeaserCard
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
            .background(Color("PrimaryBackground").edgesIgnoringSafeArea(.all))
            .onAppear {
                // Load data when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoading = false
                }
            }
            .sheet(item: $showingDetailInsight) { insight in
                InsightDetailView(insight: insight)
                    .environmentObject(mlManager)
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Metric selector and timeframe header
    private var metricSelectorHeader: some View {
        VStack(spacing: 16) {
            // Metric selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(HealthMetricType.allCases, id: \.self) { metricType in
                        Button(action: {
                            withAnimation {
                                selectedMetric = metricType
                            }
                        }) {
                            HStack {
                                Image(systemName: iconForMetric(metricType))
                                    .font(.subheadline)
                                
                                Text(metricType.displayName)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedMetric == metricType ? 
                                    Color("AccentColor") : 
                                    Color("SecondaryBackground")
                            )
                            .foregroundColor(
                                selectedMetric == metricType ? 
                                    .white : 
                                    Color("PrimaryText")
                            )
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Timeframe selector
            HStack {
                ForEach(TimeframeOption.allCases, id: \.self) { timeframe in
                    Button(action: {
                        withAnimation {
                            selectedTimeframe = timeframe
                        }
                    }) {
                        Text(timeframe.displayName)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedTimeframe == timeframe ? 
                                    Color("AccentColor").opacity(0.2) : 
                                    Color.clear
                            )
                            .foregroundColor(
                                selectedTimeframe == timeframe ? 
                                    Color("AccentColor") : 
                                    Color("SecondaryText")
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// Main metric chart card
    private var metricChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(selectedMetric.displayName) Trends")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
                
                Text(selectedTimeframe.displayName)
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
            
            if isLoading {
                ProgressView()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else if healthMetricsData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: iconForMetric(selectedMetric))
                        .font(.system(size: 40))
                        .foregroundColor(Color("SecondaryText").opacity(0.5))
                    
                    Text("No data available")
                        .font(.headline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Text("Connect to HealthKit to see your \(selectedMetric.displayName.lowercased()) data")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText").opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(healthMetricsData) { metric in
                        LineMark(
                            x: .value("Date", metric.date ?? Date()),
                            y: .value(selectedMetric.displayName, metric.value)
                        )
                        .foregroundStyle(Color("AccentColor"))
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", metric.date ?? Date()),
                            y: .value(selectedMetric.displayName, metric.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color("AccentColor").opacity(0.5),
                                    Color("AccentColor").opacity(0.0)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", metric.date ?? Date()),
                            y: .value(selectedMetric.displayName, metric.value)
                        )
                        .foregroundStyle(Color("AccentColor"))
                    }
                    
                    RuleMark(y: .value("Average", dailyAverage))
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Avg: \(formatValue(dailyAverage, for: selectedMetric))")
                                .font(.caption)
                                .foregroundColor(Color("SecondaryText"))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color("SecondaryBackground").opacity(0.8))
                                .cornerRadius(4)
                        }
                }
                .chartYScale(domain: .automatic(includesZero: true))
                .chartXAxis {
                    AxisMarks(values: .stride(by: selectedTimeframe.strideBy)) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                Text(selectedTimeframe.formatDate(date))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .chartLegend(.hidden)
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(16)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    /// Metric summary card
    private var metricSummaryCard: some View {
        HStack(spacing: 16) {
            // Daily average
            VStack(spacing: 8) {
                Text("Daily Average")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                
                Text(formatValue(dailyAverage, for: selectedMetric))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("PrimaryText"))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("SecondaryBackground"))
            .cornerRadius(12)
            
            // Weekly trend
            VStack(spacing: 8) {
                Text("Weekly Trend")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                
                HStack(spacing: 4) {
                    Image(systemName: weeklyTrend.icon)
                        .foregroundColor(colorForTrend(weeklyTrend, metricType: selectedMetric))
                    
                    Text(weeklyTrend.description)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("PrimaryText"))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("SecondaryBackground"))
            .cornerRadius(12)
            
            // Current streak
            VStack(spacing: 8) {
                Text("Current Streak")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
                
                HStack(spacing: 4) {
                    Text("\(streakData.currentStreak)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text("days")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("SecondaryBackground"))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    /// AI-generated insights section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showFilters.toggle()
                    }
                }) {
                    Label("Filter", systemImage: "slider.horizontal.3")
                        .font(.subheadline)
                        .foregroundColor(Color("AccentColor"))
                }
            }
            .padding(.horizontal)
            
            // Category filter
            if showFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(InsightCategory.allCases, id: \.self) { category in
                            Button(action: {
                                withAnimation {
                                    selectedInsightCategory = category
                                }
                            }) {
                                Text(category.displayName)
                                    .font(.subheadline)
                                    .fontWeight(selectedInsightCategory == category ? .semibold : .regular)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedInsightCategory == category ? 
                                            Color("AccentColor") : 
                                            Color("SecondaryBackground")
                                    )
                                    .foregroundColor(
                                        selectedInsightCategory == category ? 
                                            .white : 
                                            Color("PrimaryText")
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if insights.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 40))
                        .foregroundColor(Color("SecondaryText").opacity(0.5))
                    
                    Text("No insights available yet")
                        .font(.headline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Text("Continue tracking your health data to receive personalized insights")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText").opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("SecondaryBackground"))
                .cornerRadius(16)
                .padding(.horizontal)
            } else {
                ForEach(insights.prefix(3)) { insight in
                    insightCard(insight)
                        .onTapGesture {
                            showingDetailInsight = insight
                        }
                }
                
                if insights.count > 3 {
                    Button(action: {
                        // Show all insights
                    }) {
                        Text("View All Insights")
                            .font(.subheadline)
                            .foregroundColor(Color("AccentColor"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("SecondaryBackground"))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    /// Weekly summary section
    private var weeklySummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Summary")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("PrimaryText"))
                .padding(.horizontal)
            
            if weeklySummary.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 40))
                        .foregroundColor(Color("SecondaryText").opacity(0.5))
                    
                    Text("No weekly data available")
                        .font(.headline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Text("Connect to HealthKit to see your weekly health summary")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText").opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("SecondaryBackground"))
                .cornerRadius(16)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(weeklySummary) { summary in
                            weeklySummaryCard(summary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    /// Correlation insights section
    private var correlationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Correlations")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("PrimaryText"))
                .padding(.horizontal)
            
            if correlationInsights.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 40))
                        .foregroundColor(Color("SecondaryText").opacity(0.5))
                    
                    Text("No correlations found yet")
                        .font(.headline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Text("Continue tracking multiple health metrics to discover correlations")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText").opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("SecondaryBackground"))
                .cornerRadius(16)
                .padding(.horizontal)
            } else {
                ForEach(correlationInsights) { correlation in
                    correlationCard(correlation)
                }
            }
        }
    }
    
    /// Related goals section
    private var relatedGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Goals")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("PrimaryText"))
                .padding(.horizontal)
            
            ForEach(relatedGoals) { goal in
                relatedGoalCard(goal)
            }
        }
    }
    
    /// Premium features teaser
    private var premiumFeaturesTeaserCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                
                Text("Premium Insights")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
            }
            
            Text("Upgrade to Premium to unlock advanced analytics, personalized recommendations, and deeper health insights.")
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
            
            Button(action: {
                // Show paywall
            }) {
                Text("Upgrade to Premium")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    /// Insight card component
    private func insightCard(_ insight: Insight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.category.icon)
                    .font(.title3)
                    .foregroundColor(insight.category.color)
                    .frame(width: 32, height: 32)
                    .background(insight.category.color.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.headline)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text(insight.category.displayName)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
                
                Text(formatDate(insight.date))
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
            }
            
            Text(insight.summary)
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
                .lineLimit(2)
            
            HStack {
                ForEach(insight.relatedMetrics, id: \.self) { metric in
                    Text(metric.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("AccentColor").opacity(0.1))
                        .foregroundColor(Color("AccentColor"))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    /// Weekly summary card component
    private func weeklySummaryCard(_ summary: HealthMetricSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForMetric(summary.type))
                    .font(.title3)
                    .foregroundColor(Color("AccentColor"))
                
                Text(summary.type.displayName)
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total:")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Spacer()
                    
                    Text(formatValue(summary.total, for: summary.type))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                }
                
                HStack {
                    Text("Average:")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Spacer()
                    
                    Text(formatValue(summary.average, for: summary.type))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                }
                
                HStack {
                    Text("Max:")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Spacer()
                    
                    Text(formatValue(summary.max, for: summary.type))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                }
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(16)
        .frame(width: 200)
    }
    
    /// Correlation card component
    private func correlationCard(_ correlation: CorrelationInsight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color("AccentColor"))
                
                Text("Correlation Found")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
                
                Text("\(Int(correlation.strength * 100))% confidence")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color("AccentColor").opacity(0.1))
                    .foregroundColor(Color("AccentColor"))
                    .cornerRadius(8)
            }
            
            Text(correlation.description)
                .font(.subheadline)
                .foregroundColor(Color("SecondaryText"))
            
            HStack {
                VStack(alignment: .center, spacing: 4) {
                    Image(systemName: iconForMetric(correlation.metricOne))
                        .font(.subheadline)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text(correlation.metricOne.displayName)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: correlation.correlationType.icon)
                    .font(.title3)
                    .foregroundColor(correlation.correlationType.color)
                
                VStack(alignment: .center, spacing: 4) {
                    Image(systemName: iconForMetric(correlation.metricTwo))
                        .font(.subheadline)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text(correlation.metricTwo.displayName)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    /// Related goal card component
    private func relatedGoalCard(_ goal: Goal) -> some View {
        HStack(spacing: 16) {
            // Goal category icon
            Image(systemName: goal.categoryIcon)
                .font(.title3)
                .foregroundColor(goal.categoryColor)
                .frame(width: 40, height: 40)
                .background(goal.categoryColor.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title ?? "Untitled Goal")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                
                // Progress bar
                HStack {
                    ProgressView(value: goal.progress, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: goal.categoryColor))
                    
                    Text("\(Int(goal.progress))%")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                        .frame(width: 40)
                }
            }
        }
        .padding()
        .background(Color("SecondaryBackground"))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Insight Detail View

struct InsightDetailView: View {
    let insight: Insight
    @EnvironmentObject private var mlManager: MLManager
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: insight.category.icon)
                        .font(.title2)
                        .foregroundColor(insight.category.color)
                        .frame(width: 50, height: 50)
                        .background(insight.category.color.opacity(0.2))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color("PrimaryText"))
                        
                        HStack {
                            Text(insight.category.displayName)
                                .font(.subheadline)
                                .foregroundColor(Color("SecondaryText"))
                            
                            Spacer()
                            
                            Text(formatDate(insight.date))
                                .font(.caption)
                                .foregroundColor(Color("SecondaryText"))
                        }
                    }
                }
                .padding()
                
                // Insight content
                VStack(alignment: .leading, spacing: 16) {
                    Text("Summary")
                        .font(.headline)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text(insight.summary)
                        .font(.body)
                        .foregroundColor(Color("SecondaryText"))
                    
                    if let details = insight.details, !details.isEmpty {
                        Text("Details")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                            .padding(.top, 8)
                        
                        Text(details)
                            .font(.body)
                            .foregroundColor(Color("SecondaryText"))
                    }
                }
                .padding()
                .background(Color("SecondaryBackground"))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Related metrics
                if !insight.relatedMetrics.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Related Health Metrics")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                        
                        ForEach(insight.relatedMetrics, id: \.self) { metric in
                            HStack {
                                Image(systemName: iconForMetric(metric))
                                    .font(.subheadline)
                                    .foregroundColor(Color("AccentColor"))
                                    .frame(width: 30, height: 30)
                                    .background(Color("AccentColor").opacity(0.1))
                                    .clipShape(Circle())
                                
                                Text(metric.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(Color("PrimaryText"))
                                
                                Spacer()
                                
                                if let value = insight.metricValues[metric] {
                                    Text(formatValue(value, for: metric))
                                        .font(.subheadline)
                                        .foregroundColor(Color("SecondaryText"))
                                }
                            }
                            .padding()
                            .background(Color("SecondaryBackground"))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color("SecondaryBackground"))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // Recommendations
                if let recommendations = insight.recommendations, !recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommendations")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                        
                        ForEach(recommendations, id: \.self) { recommendation in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color("AccentColor"))
                                    .padding(.top, 2)
                                
                                Text(recommendation)
                                    .font(.subheadline)
                                    .foregroundColor(Color("SecondaryText"))
                            }
                        }
                    }
                    .padding()
                    .background(Color("SecondaryBackground"))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .background(Color("PrimaryBackground").edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Insight Details", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("SecondaryText"))
                }
            }
        }
    }
    
    /// Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Format value based on metric type
    private func formatValue(_ value: Double, for metricType: HealthMetricType) -> String {
        switch metricType {
        case .steps:
            return "\(Int(value))"
        case .activeEnergy:
            return "\(Int(value)) kcal"
        case .heartRate:
            return "\(Int(value)) bpm"
        case .sleepHours:
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            return "\(hours)h \(minutes)m"
        case .weight:
            return String(format: "%.1f kg", value)
        case .mindfulMinutes:
            return "\(Int(value)) min"
        case .standHours:
            return "\(Int(value)) hrs"
        case .workouts:
            return "\(Int(value))"
        }
    }
    
    /// Get icon for metric type
    private func iconForMetric(_ metricType: HealthMetricType) -> String {
        switch metricType {
        case .steps:
            return "figure.walk"
        case .activeEnergy:
            return "flame"
        case .heartRate:
            return "heart"
        case .sleepHours:
            return "bed.double"
        case .weight:
            return "scalemass"
        case .mindfulMinutes:
            return "brain.head.profile"
        case .standHours:
            return "figure.stand"
        case .workouts:
            return "figure.run"
        }
    }
}

// MARK: - Supporting Types

/// Health metric type
enum HealthMetricType: String, CaseIterable {
    case steps = "steps"
    case activeEnergy = "activeEnergy"
    case heartRate = "heartRate"
    case sleepHours = "sleepHours"
    case weight = "weight"
    case mindfulMinutes = "mindfulMinutes"
    case standHours = "standHours"
    case workouts = "workouts"
    
    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .activeEnergy: return "Active Energy"
        case .heartRate: return "Heart Rate"
        case .sleepHours: return "Sleep"
        case .weight: return "Weight"
        case .mindfulMinutes: return "Mindfulness"
        case .standHours: return "Stand Hours"
        case .workouts: return "Workouts"
        }
    }
}

/// Timeframe options for data display
enum TimeframeOption: String, CaseIterable {
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .day: return "Today"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
    
    var strideBy: Calendar.Component {
        switch self {
        case .day: return .hour
        case .week: return .day
        case .month: return .day
        case .year: return .month
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch self {
        case .day:
            formatter.dateFormat = "HH:mm"
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "d MMM"
        case .year:
            formatter.dateFormat = "MMM"
        }
        
        return formatter.string(from: date)
    }
}

/// Trend direction
enum TrendDirection {
    case up
    case down
    case stable
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "equal.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .up: return "Increasing"
        case .down: return "Decreasing"
        case .stable: return "Stable"
        }
    }
}

/// Insight category
enum InsightCategory: String, CaseIterable {
    case all = "all"
    case activity = "activity"
    case sleep = "sleep"
    case nutrition = "nutrition"
    case mindfulness = "mindfulness"
    case cardio = "cardio"
    case weight = "weight"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .activity: return "Activity"
        case .sleep: return "Sleep"
        case .nutrition: return "Nutrition"
        case .mindfulness: return "Mindfulness"
        case .cardio: return "Cardiovascular"
        case .weight: return "Weight"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .activity: return "figure.walk"
        case .sleep: return "bed.double"
        case .nutrition: return "fork.knife"
        case .mindfulness: return "brain.head.profile"
        case .cardio: return "heart"
        case .weight: return "scalemass"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return Color("AccentColor")
        case .activity: return .orange
        case .sleep: return .purple
        case .nutrition: return .green
        case .mindfulness: return .blue
        case .cardio: return .red
        case .weight: return .gray
        }
    }
}

/// Correlation type
enum CorrelationType {
    case positive
    case negative
    case mixed
    
    var icon: String {
        switch self {
        case .positive: return "arrow.up.forward"
        case .negative: return "arrow.down.forward"
        case .mixed: return "arrow.up.arrow.down"
        }
    }
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .mixed: return .orange
        }
    }
}

// MARK: - Data Models

/// Health metric summary
struct HealthMetricSummary: Identifiable {
    let id = UUID()
    let type: HealthMetricType
    let total: Double
    let average: Double
    let max: Double
}

/// Insight model
struct Insight: Identifiable {
    let id: UUID
    let title: String
    let summary: String
    let details: String?
    let category: InsightCategory
    let date: Date
    let relatedMetrics: [HealthMetricType]
    let metricValues: [HealthMetricType: Double]
    let recommendations: [String]?
}

/// Correlation insight model
struct CorrelationInsight: Identifiable {
    let id = UUID()
    let metricOne: HealthMetricType
    let metricTwo: HealthMetricType
    let correlationType: CorrelationType
    let strength: Double // 0.0 to 1.0
    let description: String
}

/// Streak information
struct StreakInfo {
    let currentStreak: Int
    let bestStreak: Int
    let lastCompletedDate: Date?
}

// MARK: - Goal Extensions

extension Goal {
    func isRelatedToHealthMetric(_ metricType: HealthMetricType) -> Bool {
        guard let category = self.category else { return false }
        
        switch metricType {
        case .steps:
            return category == "fitness" || category == "health"
        case .activeEnergy:
            return category == "fitness" || category == "health"
        case .heartRate:
            return category == "health" || category == "cardio"
        case .sleepHours:
            return category == "sleep" || category == "health"
        case .weight:
            return category == "health" || category == "nutrition"
        case .mindfulMinutes:
            return category == "mindfulness"
        case .standHours:
            return category == "fitness" || category == "health"
        case .workouts:
            return category == "fitness" || category == "health"
        }
    }
}

// MARK: - Preview
struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(HealthKitManager())
            .environmentObject(MLManager())
            .environmentObject(UserProfileManager())
            .environmentObject(StoreManager())
    }
}
