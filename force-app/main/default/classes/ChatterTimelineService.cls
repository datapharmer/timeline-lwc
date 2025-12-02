/**
 * @description Service class for handling Chatter-specific timeline data
 * @author Timeline LWC Team
 * @date 2024
 */
public with sharing class ChatterTimelineService {
    
    /**
     * @description Retrieves Chatter feed items for a given parent record
     * @param parentId The ID of the parent record
     * @param dateFilter The date filter criteria
     * @return List of timeline data for Chatter posts
     */
    @AuraEnabled(cacheable=true)
    public static List<TimelineData> getChatterTimelineData(Id parentId, Map<String, Object> dateFilter) {
        List<TimelineData> timelineData = new List<TimelineData>();
        
        try {
            // Get feed items for the parent record
            List<FeedItem> feedItems = getFeedItems(parentId, dateFilter);
            
            // Convert FeedItems to TimelineData
            for (FeedItem item : feedItems) {
                TimelineData data = new TimelineData();
                data.recordId = item.Id;
                data.parentId = parentId;
                data.objectName = 'FeedItem';
                data.dateValue = item.CreatedDate;
                data.detailField = item.Body;
                data.tooltipId = item.Id;
                data.tooltipObject = 'FeedItem';
                data.drilldownId = item.Id;
                data.type = item.Type;
                data.icon = getIconForFeedType(item.Type);
                data.iconBackground = getIconColorForFeedType(item.Type);
                data.createdBy = item.CreatedBy.Name;
                data.createdById = item.CreatedById;
                
                // Add attachment information if present
                if (item.HasContent) {
                    data.hasAttachment = true;
                    data.attachmentCount = item.RelatedRecordId != null ? 1 : 0;
                }
                
                // Add comment count
                data.commentCount = [SELECT COUNT() FROM FeedComment WHERE FeedItemId = :item.Id];
                
                timelineData.add(data);
            }
            
            // Get feed comments if needed
            List<FeedComment> feedComments = getFeedComments(parentId, dateFilter);
            for (FeedComment comment : feedComments) {
                TimelineData data = new TimelineData();
                data.recordId = comment.Id;
                data.parentId = parentId;
                data.objectName = 'FeedComment';
                data.dateValue = comment.CreatedDate;
                data.detailField = comment.CommentBody;
                data.tooltipId = comment.Id;
                data.tooltipObject = 'FeedComment';
                data.drilldownId = comment.FeedItemId;
                data.type = 'Comment';
                data.icon = 'standard:feedback';
                data.iconBackground = '#481A54';
                data.createdBy = comment.CreatedBy.Name;
                data.createdById = comment.CreatedById;
                data.parentPostId = comment.FeedItemId;
                
                timelineData.add(data);
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving Chatter timeline data: ' + e.getMessage());
        }
        
        return timelineData;
    }
    
    /**
     * @description Get feed items for a parent record
     */
    private static List<FeedItem> getFeedItems(Id parentId, Map<String, Object> dateFilter) {
        String query = 'SELECT Id, Body, Type, CreatedDate, CreatedById, CreatedBy.Name, ' +
                      'HasContent, RelatedRecordId, Title, LinkUrl ' +
                      'FROM FeedItem WHERE ParentId = :parentId';
        
        // Filter out certain types if needed
        query += ' AND Type IN (\'TextPost\', \'LinkPost\', \'ContentPost\', \'TrackedChange\', \'QuestionPost\')';
        query += ' ORDER BY CreatedDate DESC LIMIT 100';
        
        return Database.query(query);
    }
    
    /**
     * @description Get feed comments for feed items related to a parent record
     */
    private static List<FeedComment> getFeedComments(Id parentId, Map<String, Object> dateFilter) {
        // First get the feed item IDs for the parent
        Set<Id> feedItemIds = new Set<Id>();
        for (FeedItem item : [SELECT Id FROM FeedItem WHERE ParentId = :parentId]) {
            feedItemIds.add(item.Id);
        }
        
        if (feedItemIds.isEmpty()) {
            return new List<FeedComment>();
        }
        
        String query = 'SELECT Id, FeedItemId, CommentBody, CreatedDate, CreatedById, CreatedBy.Name ' +
                      'FROM FeedComment WHERE FeedItemId IN :feedItemIds';
        
        query += ' ORDER BY CreatedDate DESC LIMIT 200';
        
        return Database.query(query);
    }
    
    /**
     * @description Get appropriate icon for feed type
     */
    private static String getIconForFeedType(String feedType) {
        Map<String, String> feedTypeIconMap = new Map<String, String>{
            'TextPost' => 'standard:post',
            'LinkPost' => 'standard:link',
            'ContentPost' => 'standard:file',
            'TrackedChange' => 'standard:feed',
            'QuestionPost' => 'standard:question_feed',
            'PollPost' => 'standard:poll'
        };
        
        return feedTypeIconMap.containsKey(feedType) ? 
               feedTypeIconMap.get(feedType) : 'standard:post';
    }
    
    /**
     * @description Get appropriate icon color for feed type
     */
    private static String getIconColorForFeedType(String feedType) {
        Map<String, String> feedTypeColorMap = new Map<String, String>{
            'TextPost' => '#16325C',
            'LinkPost' => '#3E3E3C',
            'ContentPost' => '#BA0517',
            'TrackedChange' => '#54698D',
            'QuestionPost' => '#F8A901',
            'PollPost' => '#4BCA81'
        };
        
        return feedTypeColorMap.containsKey(feedType) ? 
               feedTypeColorMap.get(feedType) : '#16325C';
    }
    
    /**
     * @description Create a new Chatter post from the timeline
     */
    @AuraEnabled
    public static FeedItem createChatterPost(Id parentId, String body, String type) {
        FeedItem post = new FeedItem();
        post.ParentId = parentId;
        post.Body = body;
        post.Type = type != null ? type : 'TextPost';
        
        insert post;
        return post;
    }
    
    /**
     * @description Add a comment to an existing feed item
     */
    @AuraEnabled
    public static FeedComment addChatterComment(Id feedItemId, String commentBody) {
        FeedComment comment = new FeedComment();
        comment.FeedItemId = feedItemId;
        comment.CommentBody = commentBody;
        
        insert comment;
        return comment;
    }
    
    /**
     * @description Inner class to represent timeline data
     */
    public class TimelineData {
        @AuraEnabled public Id recordId { get; set; }
        @AuraEnabled public Id parentId { get; set; }
        @AuraEnabled public String objectName { get; set; }
        @AuraEnabled public DateTime dateValue { get; set; }
        @AuraEnabled public String detailField { get; set; }
        @AuraEnabled public Id tooltipId { get; set; }
        @AuraEnabled public String tooltipObject { get; set; }
        @AuraEnabled public Id drilldownId { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String icon { get; set; }
        @AuraEnabled public String iconBackground { get; set; }
        @AuraEnabled public String createdBy { get; set; }
        @AuraEnabled public Id createdById { get; set; }
        @AuraEnabled public Boolean hasAttachment { get; set; }
        @AuraEnabled public Integer attachmentCount { get; set; }
        @AuraEnabled public Integer commentCount { get; set; }
        @AuraEnabled public Id parentPostId { get; set; }
        
        public TimelineData() {
            hasAttachment = false;
            attachmentCount = 0;
            commentCount = 0;
        }
    }
}
