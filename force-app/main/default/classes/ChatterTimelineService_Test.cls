/**
 * @description Test class for ChatterTimelineService
 * @author Timeline LWC Team
 * @date 2024
 */
@IsTest
private class ChatterTimelineService_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account for Chatter');
        insert testAccount;
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create test feed items
        List<FeedItem> feedItems = new List<FeedItem>();
        
        FeedItem textPost = new FeedItem(
            ParentId = testAccount.Id,
            Body = 'Test text post',
            Type = 'TextPost'
        );
        feedItems.add(textPost);
        
        FeedItem linkPost = new FeedItem(
            ParentId = testAccount.Id,
            Body = 'Test link post',
            LinkUrl = 'https://www.salesforce.com',
            Title = 'Salesforce',
            Type = 'LinkPost'
        );
        feedItems.add(linkPost);
        
        insert feedItems;
        
        // Create test feed comments
        FeedComment testComment = new FeedComment(
            FeedItemId = textPost.Id,
            CommentBody = 'Test comment on text post'
        );
        insert testComment;
    }
    
    @IsTest
    static void testGetChatterTimelineData() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Chatter' LIMIT 1];
        
        Test.startTest();
        List<ChatterTimelineService.TimelineData> timelineData = 
            ChatterTimelineService.getChatterTimelineData(testAccount.Id, null);
        Test.stopTest();
        
        System.assertNotEquals(null, timelineData, 'Timeline data should not be null');
        System.assert(timelineData.size() > 0, 'Should have timeline data');
        
        // Check for feed items
        Boolean hasFeedItem = false;
        Boolean hasComment = false;
        for (ChatterTimelineService.TimelineData data : timelineData) {
            if (data.objectName == 'FeedItem') {
                hasFeedItem = true;
            }
            if (data.objectName == 'FeedComment') {
                hasComment = true;
            }
        }
        
        System.assert(hasFeedItem, 'Should have at least one FeedItem');
        System.assert(hasComment, 'Should have at least one FeedComment');
    }
    
    @IsTest
    static void testGetChatterTimelineDataWithDateFilter() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Chatter' LIMIT 1];
        
        Map<String, Object> dateFilter = new Map<String, Object>{
            'startDate' => DateTime.now().addDays(-7),
            'endDate' => DateTime.now().addDays(1)
        };
        
        Test.startTest();
        List<ChatterTimelineService.TimelineData> timelineData = 
            ChatterTimelineService.getChatterTimelineData(testAccount.Id, dateFilter);
        Test.stopTest();
        
        System.assertNotEquals(null, timelineData, 'Timeline data should not be null');
        System.assert(timelineData.size() > 0, 'Should have timeline data within date range');
    }
    
    @IsTest
    static void testCreateChatterPost() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Chatter' LIMIT 1];
        
        Test.startTest();
        FeedItem newPost = ChatterTimelineService.createChatterPost(
            testAccount.Id, 
            'New test post from timeline', 
            'TextPost'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, newPost, 'New post should not be null');
        System.assertNotEquals(null, newPost.Id, 'New post should have an ID');
        System.assertEquals('New test post from timeline', newPost.Body, 'Post body should match');
    }
    
    @IsTest
    static void testAddChatterComment() {
        FeedItem testPost = [SELECT Id FROM FeedItem WHERE Body = 'Test text post' LIMIT 1];
        
        Test.startTest();
        FeedComment newComment = ChatterTimelineService.addChatterComment(
            testPost.Id,
            'New comment from timeline'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, newComment, 'New comment should not be null');
        System.assertNotEquals(null, newComment.Id, 'New comment should have an ID');
        System.assertEquals('New comment from timeline', newComment.CommentBody, 'Comment body should match');
    }
    
    @IsTest
    static void testGetIconForFeedType() {
        // This is a private method, so we test it indirectly through getChatterTimelineData
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Chatter' LIMIT 1];
        
        Test.startTest();
        List<ChatterTimelineService.TimelineData> timelineData = 
            ChatterTimelineService.getChatterTimelineData(testAccount.Id, null);
        Test.stopTest();
        
        for (ChatterTimelineService.TimelineData data : timelineData) {
            if (data.type == 'TextPost') {
                System.assertEquals('standard:post', data.icon, 'TextPost should have post icon');
            } else if (data.type == 'LinkPost') {
                System.assertEquals('standard:link', data.icon, 'LinkPost should have link icon');
            }
        }
    }
    
    @IsTest
    static void testErrorHandling() {
        // Test with invalid parent ID
        Id invalidId = '001000000000000AAA';
        
        Test.startTest();
        try {
            List<ChatterTimelineService.TimelineData> timelineData = 
                ChatterTimelineService.getChatterTimelineData(invalidId, null);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error retrieving Chatter timeline data'), 
                         'Should throw appropriate error');
        }
        Test.stopTest();
    }
}
