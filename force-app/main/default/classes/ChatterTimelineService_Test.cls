/**
 * @description Test class for ChatterTimelineService
 */
@IsTest
private class ChatterTimelineService_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account for Chatter');
        insert testAccount;
    }
    
    @IsTest
    static void testGetChatterTimelineData() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Chatter' LIMIT 1];
        
        // Create test feed item
        FeedItem testPost = new FeedItem(
            ParentId = testAccount.Id,
            Body = 'Test post',
            Type = 'TextPost'
        );
        insert testPost;
        
        Test.startTest();
        List<ChatterTimelineService.TimelineData> timelineData = 
            ChatterTimelineService.getChatterTimelineData(testAccount.Id, null);
        Test.stopTest();
        
        System.assertNotEquals(null, timelineData, 'Timeline data should not be null');
        System.assert(timelineData.size() > 0, 'Should have timeline data');
    }
    
    @IsTest
    static void testCreateChatterPost() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Chatter' LIMIT 1];
        
        Test.startTest();
        FeedItem newPost = ChatterTimelineService.createChatterPost(
            testAccount.Id, 
            'New test post', 
            'TextPost'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, newPost.Id, 'New post should have an ID');
    }
}
