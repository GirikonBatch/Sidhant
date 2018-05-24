public class Submit{
public string CaseID{get;set;} // Case ID  to be processed
List<EmailMessage> lemail = new List<EmailMessage>(); // list of emails to be archived
List<Attachment> lattach = new List<Attachment>();
List<Attachment> lemailpdf = new List<Attachment>(); // list to contain PDF for archived emails
List<Attachment> lparser = new List<attachment>();  //list to contain parser
public String aid='';//string to store attachment id for every email
public List<Integer> lint=new LISt<Integer>();
public List<EmailMessage> emailRestore=new List<EmailMEssage>();//email list to restore
public Submit( ApexPages.StandardController controller){
CaseID=apexpages.currentpage().getparameters().get('id');
}
//public Submit(ApexPages.StandardController controller){}
public PageReference Submit1()
{
CaseID=apexpages.currentpage().getparameters().get('id');

for( EmailMessage em :[select ActivityId,BccAddress,CcAddress,CreatedById,CreatedDate,FromAddress,FromName,HasAttachment,Headers,HtmlBody,Id,Incoming,IsClientManaged,IsDeleted,IsExternallyVisible,LastModifiedById,LastModifiedDate,MessageDate,MessageIdentifier,ParentId,RelatedToId,ReplyToEmailMessageId,Status,Subject,TextBody,ToAddress,ValidatedFromAddress,Counter__c FROM EmailMessage where ParentId=:CaseID])
{
lemail.add(em); //list of emails to be deleted
// Converting every email into a new attachment of type pdf
String pdfContent = 'Name:'+ em.FromAddress + '<br>'+'Subject:'+em.subject + '<br>' + 'Body:'+em.textBody;
Attachment attachmentPDF = new Attachment();
attachmentPdf.parentId = CaseID;
attachmentPdf.name = 'EM'+em.Counter__c+'.pdf';
attachmentPdf.body = blob.toPDF(pdfContent);
lemailpdf.add(attachmentPdf);//adding every pdf_Attachment to a list for insertion later on


//converting  attachments of every email to case attachments by chnging their parent id

    for(attachment a:[select id,name,parentID,body from attachment where parentid=:em.id])
    {     
    Attachment att=new Attachment();
    att.body=a.body;
    att.parentId=CaseID;
    att.name=em.Counter__c + '_' + a.name ;
    lattach.add(att);
    }
   }
insert lattach;
    
    //creating a email info parser file for retreiving email back
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
    System.debug('############'+aid);
    aid='';
}

insert lemailpdf;
delete lemail;
insert lparser;

PageReference pg=new PageReference('/'+ CaseID);
return pg;
}

public PageReference DontRestore()
{
CaseID=apexpages.currentpage().getparameters().get('id');
PageReference pg=new PageReference('/'+CaseID);
return pg;
}





/////////////////////////////////////RESTORE
public PageReference Submit2(){
List<String> atids = new List<String>();
Map<integer,List<id>> EmailAttachementMap=new Map<integer,List<id>>();
integer i=0;
for(Attachment at:[Select Id,ParentId,Name,body From Attachment where name like 'Parser%' and ParentID=:CaseID])
 {


    //Reading PArser File and creating a email corresponding to every parser and fetching attachment ids in parser
    String bodyContent = at.body.toString(); //bodyContent is body of parser file
    String[] lstring = bodycontent.split('#%#');
    //system.debug('############################'+ lstring);

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
    system.debug('###########IFLOOOPTESTED&&&&&&&&&&&');
    atids = lstring[12].split(';'); //atids contains  attachment ids stored in parser file
    }
    // Storing list of ids
    if(atids.size()>0)
    {
    system.debug('##########ATTACHMENTIDS##########'+atids);
    List<id> AttachmentsID=new List<id>(); // this will contain attachment ids to be inserted       
        For(integer j=0;j<atids.size();j++)
        {    Attachment b=new Attachment();
             b = [SELECT Body,BodyLength,ContentType,CreatedById,CreatedDate,Description,Id,
               IsDeleted,IsPrivate,LastModifiedById,LastModifiedDate,Name,OwnerId,ParentId,SystemModstamp FROM Attachment WHERE id=:atids[j]];
            AttachmentsID.add(b.id);
            System.debug('######################### '+ b);
        } 
               EmailAttachementMap.put(i++,AttachmentsID);
               SYstem.debug('#############'+ AttachmentsID +'   '+ i);

    }
}

insert emailrestore;

 
    
        Map<id,List<id>> EmailAttachementMap1=new Map<id,List<id>>();
        
        
        for(integer j=0;j<emailrestore.size();j++){
        EmailAttachementMap1.put(emailrestore[j].id, EmailAttachementMap.get(j)) ;  
        EmailAttachementMap.remove(j);
        }
        //for loop close
        
        System.debug('++++++++++++++++++++++++'+EmailAttachementMap1);
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
        }//For loop close
       
       insert atmList; //inser
       //delete atmLis;
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
        //Delete ParserfilesDelete;
        //Delete EmailfilesDelete;
    }

}