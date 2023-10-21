using System.Net.Http;
using System.Net;
using System.Web;
using System.Web.Http;
using System.IO;
using System;

namespace WebApiDotNetFramework.Controllers
{
    public class FilesController : ApiController
    {
        string path = Environment.GetEnvironmentVariable("PATH_TO_REMOTE_FILES");
        //string path = $@"{Path.GetPathRoot(Environment.SystemDirectory)}\mounts\remote-files\";

        public HttpResponseMessage Get()
        {
            // List files in the directory
            string[] files = Directory.GetFiles(path);

            return Request.CreateResponse(HttpStatusCode.OK, files);
        }

        public HttpResponseMessage PostFormData()
        {

            //Fetch the File.
            HttpPostedFile postedFile = HttpContext.Current.Request.Files[0];

            try
            {

                // The easy way: same credentials, same domain
                postedFile.SaveAs(path + postedFile.FileName);

                // Get values from environment variables
                string REMOTE_COMPUTER_NAME = Environment.GetEnvironmentVariable("REMOTE_COMPUTER_NAME");
                string USER_NAME = Environment.GetEnvironmentVariable("USER_NAME");
                string PASSWORD = Environment.GetEnvironmentVariable("PASSWORD");

                // The hard way: different credentials, different domain
                //https://stackoverflow.com/questions/659013/accessing-a-shared-file-unc-from-a-remote-non-trusted-domain-with-credentials/684040#684040
                using ((NetworkShareAccesser.Access(REMOTE_COMPUTER_NAME, USER_NAME, PASSWORD)))
                {
                    postedFile.SaveAs($@"\\{REMOTE_COMPUTER_NAME}\test\{postedFile.FileName}");
                }


                return Request.CreateResponse(HttpStatusCode.OK);
            }
            catch (System.Exception e)
            {
                return Request.CreateErrorResponse(HttpStatusCode.InternalServerError, e);
            }
        }
    }
}