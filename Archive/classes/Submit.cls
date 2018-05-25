public class Submit{
    public string CASEID{get; set;}
    public string pdf;
    public List<Attachment> lemailspdf=new List<Attachment>();
    map<id, EmailMessage> Emm;         
    map<id, attachment> emattm;
     public  List<attachment> att_insert = new list<attachment>();
 public List<Attachment> lparser=new List<Attachment>();  
    public List<Emailmessage> lemail=new List<emailmessage>();
    public List<EmailMessage> emailrestore=new  List<EmailMessage>();
    public String aid='';


    public submit(Apexpages.StandardController controller){
        
        CaseID=apexpages.currentpage().getparameters().get('id');

        
    }
    public void submit1(){
        CaseID=apexpages.currentpage().getparameters().get('id');

  
        emm = new map<id, EmailMessage>([SELECT ActivityId,BccAddress,CcAddress,CreatedById,CreatedDate,Counter__c,FromAddress,FromName,
                                              HasAttachment,Headers,HtmlBody,Id,Incoming,IsClientManaged,IsDeleted,IsExternallyVisible,
                                              LastModifiedById,LastModifiedDate,MessageDate,MessageIdentifier,ParentId,RelatedToId,
                                              ReplyToEmailMessageId,Status,Subject,SystemModstamp,TextBody,ThreadIdentifier,ToAddress,
                                              ValidatedFromAddress FROM EmailMessage where ParentId =:caseid ]) ;
        
        emattm = new  map<id, attachment>([SELECT Body,BodyLength,ContentType,CreatedById,CreatedDate,Description,Id,
                                             IsDeleted,IsPrivate,LastModifiedById,LastModifiedDate,Name,OwnerId,ParentId,
                                             SystemModstamp FROM Attachment where ParentId in : emm.keySet()]);
 
        for(attachment att : emattm.values()){
                    
                      attachment atch = new attachment();
                    
                    EmailMessage ec =  emm.get(att.ParentId);
                    
                    atch.Body = att.Body;
                    atch.ContentType = att.ContentType;
                    atch.Description = att.Description;
                    atch.IsPrivate =  att.IsPrivate;
                    atch.Name  =  ec.Counter__c+'_'+ec.Subject+'__Attachment_'+ att.Name;
                    atch.OwnerId = att.OwnerId;
                    atch.ParentId = ec.ParentId ;
                    att_insert.add(atch);
      
                  }

        ////////// email message
        for(emailmessage em:[select ActivityId,BccAddress,CcAddress,CreatedById,CreatedDate,FromAddress,FromName,HasAttachment,Headers,HtmlBody,Id,Incoming,IsClientManaged,IsDeleted,IsExternallyVisible,LastModifiedById,LastModifiedDate,MessageDate,MessageIdentifier,ParentId,RelatedToId,ReplyToEmailMessageId,Status,Subject,TextBody,ToAddress,ValidatedFromAddress,Counter__c FROM EmailMessage where ParentId=:CaseID])
        
        {
            lemail.add(em);
String pdf = 'Name:'+ em.FromAddress + '<br>'+'Subject:'+em.subject + '<br>' + 'Body:'+em.textBody;
          Attachment attachmentPDF = new Attachment();
attachmentPdf.parentId = CaseID;
attachmentPdf.name = 'EM'+em.Counter__c+'.pdf';
attachmentPdf.body = blob.toPDF(pdf);
lemailspdf.add(attachmentPdf);//adding every pdf_Attachment to a list for insertion later on

    }
           ////// parcer
       for(EmailMessage em:lemail)
    {
        for( Attachment a:[select id,name,parentID,body from attachment where parentid=:CaseID and name like :(em.Counter__c+'%')])
        {
        aid=a.id+';';
        }   
    Attachment at = new Attachment();
    at.parentId = CaseID;
    at.name='Parser'+em.Counter__c+'.txt';
    at.body = blob.valueOf ('#%#'+em.BccAddress+
                            '#%#'+em.CcAddress+
                            '#%#'+em.FromAddress+
                            '#%#'+em.FromName+
                            '#%#'+em.Headers+
                            '#%#'+em.Incoming+
                            '#%#'+em.MessageDate+
                            '#%#'+CaseID+
                            '#%#'+em.Status+
                            '#%#'+em.ToAddress+
                            '#%#'+em.Subject+
                            '#%#'+aid); // it stores old attachment id we need new ids
    lparser.add(at);
    aid='';
}

insert lemailspdf;
delete lemail;
insert lparser;
        insert lemailspdf;
delete lemailspdf;
            
    

    }
/////////////////////////////////////RESTORE////
public Pagereference Submit2(){
List<String> atids = new List<String>();
Map<integer,List<id>> EmailAttachementMap=new Map<integer,List<id>>();
integer i=0;
for(Attachment at:[Select Id,ParentId,Name,body From Attachment where name like 'Parser%' and ParentID=:CaseID])
 {


    //Reading PArser File and creating a email corresponding to every parser and fetching attachment ids in parser
    String bodyContent = at.body.toString(); //bodyContent is body of parser file
    String[] lstring = bodycontent.split('#%#');

    EmailMessage em=new EmailMessage();
    em.BccAddress=lstring[1];
    em.CcAddress=lstring[2];
    em.FromAddress=lstring[3];
    em.FromName=lstring[4];
    em.Headers=lstring[5];
    em.ParentId=CaseID;
    em.ToAddress=lstring[10];
    em.Subject=lstring[11];
    emailrestore.add(em);
    
    if(lstring.size()==13)
    {
    atids = lstring[12].split(';'); //atids contains  attachment ids stored in parser file
    }
    // Storing list of ids
    if(atids.size()>0)
    {
    List<id> AttachmentsID=new List<id>(); // this will contain attachment ids to be inserted       
        For(integer j=0;j<atids.size();j++)
        {    Attachment b=new Attachment();
             b = [SELECT Body,BodyLength,ContentType,CreatedById,CreatedDate,Description,Id,
               IsDeleted,IsPrivate,LastModifiedById,LastModifiedDate,Name,OwnerId,ParentId,SystemModstamp FROM Attachment WHERE id=:atids[j]];
            AttachmentsID.add(b.id);
        } 
               EmailAttachementMap.put(i++,AttachmentsID);

    }
}

insert emailrestore;

 
    
        Map<id,List<id>> EmailAttachementMap1=new Map<id,List<id>>();
        
        
        for(integer j=0;j<emailrestore.size();j++){
        EmailAttachementMap1.put(emailrestore[j].id, EmailAttachementMap.get(j)) ;  
        EmailAttachementMap.remove(j);
        }
        //for loop close
        
       List<Attachment> atmList=new List<Attachment>();
        List<Attachment> atmLis=new List<Attachment>();
         for(id p_id : EmailAttachementMap1.keySet() )   // traversing list of inserted email ids in map
         {     
              
             if(EmailAttachementMap1.get(p_id) != NULL){
                 for(attachment attm : [select Body,BodyLength,ContentType,CreatedById,CreatedDate,Description,Id,
                                            IsDeleted,IsPrivate,LastModifiedById,LastModifiedDate,Name,OwnerId,
                                            ParentId,SystemModstamp from attachment where id in : EmailAttachementMap1.get(p_id)])
            {
                    
                    attachment atch = new attachment();
                    atch.Body = attm.Body;
                    atch.ContentType = attm.ContentType;
                    atch.Description = attm.Description;
                    atch.IsPrivate =  attm.IsPrivate;
                    atch.Name  = attm.Name.substringAfterLast('_') ;
                    atch.OwnerId = attm.OwnerId;
                    atch.ParentId =p_id;
                    atmList.add(atch);  
                    atmLis.add(attm);                    
               }
             }  
        }
       
       insert atmList; 
       
       del();

    PageReference pg=new PageReference('/'+CaseID);
    return pg;
}
void del()
    {
        List<Attachment> ParserfilesDelete=new List<Attachment>();
        List<Attachment> EmailfilesDelete=new List<Attachment>();
         ParserfilesDelete=[Select Id,ParentId,Name,body,ContentType From Attachment where name like 'Parser%.txt' and ParentId=:CaseID];
         EmailfilesDelete=[Select Id,ParentId,Name,body,ContentType From Attachment where name like 'EM%.pdf' and ParentId=:CaseID];
       
    }
}