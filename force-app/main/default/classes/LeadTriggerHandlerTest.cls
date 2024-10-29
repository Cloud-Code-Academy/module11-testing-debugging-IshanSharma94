@IsTest
public with sharing class LeadTriggerHandlerTest {
    
    @isTest
    public static void testHandleTitleNormalization() {
        List<Lead> leadsInserted = new List<Lead>{
            new Lead(FirstName = 'John', LastName = 'Doe', Title = 'vp', Company = 'Test Company1'),
            new Lead(FirstName = 'Jane', LastName = 'Smith', Title = 'head of department', Company = 'Test Company2'),
            new Lead(FirstName = 'Alan', LastName = 'Turing', Title = 'exec', Company = 'Test Company3'),
            new Lead(FirstName = 'Emily', LastName = 'Clark', Title = 'deputy', Company = 'Test Company4')
        };
        insert leadsInserted;

        List<Lead> retrievedLeads = [SELECT Id, Title FROM Lead WHERE Id IN :leadsInserted];
        System.assertEquals('Vice President', retrievedLeads[0].Title, 'Title should be normalized to Vice President');
        System.assertEquals('Manager', retrievedLeads[1].Title, 'Title should be normalized to Manager');
        System.assertEquals('Executive', retrievedLeads[2].Title, 'Title should be normalized to Executive');
        System.assertEquals('Assistant', retrievedLeads[3].Title, 'Title should be normalized to Assistant');
    }
    
    @isTest
    public static void testHandleAutoLeadScoring() {
        List<Lead> leadsInserted = new List<Lead>{
            new Lead(FirstName = 'Alice', LastName = 'Johnson', Company = 'Test Company1', LeadSource = 'Web', Email = 'alice@example.com', Industry = 'Technology'),
            new Lead(FirstName = 'Bob', LastName = 'Brown', Company = 'Test Company2', LeadSource = 'Event', Phone = '123-456-7890'),
            new Lead(FirstName = 'Charlie', LastName = 'Davis', Company = 'Test Company3', Industry = 'Technology'),
            new Lead(FirstName = 'Diana', LastName = 'Evans', Company = 'Test Company4', Phone = '098-765-4321')
        };
        insert leadsInserted;

        List<Lead> retrievedLeads = [SELECT Id, Lead_Score__c FROM Lead WHERE Id IN :leadsInserted];
        System.assertEquals(13, retrievedLeads[0].Lead_Score__c, 'Lead score should be 13');
        System.assertEquals(5, retrievedLeads[1].Lead_Score__c, 'Lead score should be 5');
        System.assertEquals(10, retrievedLeads[2].Lead_Score__c, 'Lead score should be 10');
        System.assertEquals(5, retrievedLeads[3].Lead_Score__c, 'Lead score should be 5');
    }

    @isTest
    public static void testHandleLeadAutoConvert() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact existingContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'testcontact@example.com', AccountId = acc.id);
        insert existingContact;

        Lead leadToConvert = new Lead(FirstName = 'Convert', LastName = 'Lead', Company = 'Test Account', Email = 'testcontact@example.com');
        
        Test.startTest();
        insert leadToConvert;
        Test.stopTest();

        Lead convertedLead = [SELECT IsConverted, ConvertedContactId FROM Lead WHERE Id = :leadToConvert.Id];
        System.assert(convertedLead.IsConverted, 'Lead should be marked as converted');
        System.assertEquals(existingContact.Id, convertedLead.ConvertedContactId, 'Lead should be converted to the existing contact');
    }
    
    @isTest
    static void testNoLeadAutoConvertForMultipleContacts() {
        Contact duplicateContact1 = new Contact(FirstName = 'Duplicate', LastName = 'Contact1', Email = 'testduplicate@example.com');
        Contact duplicateContact2 = new Contact(FirstName = 'Duplicate', LastName = 'Contact2', Email = 'testduplicate@example.com');
        insert new List<Contact>{duplicateContact1,duplicateContact2};

        Lead leadToNotConvert = new Lead(FirstName = 'No Convert', LastName = 'Lead', Company = 'No Convert Company', Email = 'testduplicate@example.com');
        
        Test.startTest();
        insert leadToNotConvert;
        Test.stopTest();
        
        Lead nonConvertedLead = [SELECT IsConverted FROM Lead WHERE Id = :leadToNotConvert.Id];
        System.assert(!nonConvertedLead.IsConverted, 'Lead should not be converted when multiple contacts are found');
    }
}