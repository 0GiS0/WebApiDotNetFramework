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
        // Get values from environment variables
        readonly string REMOTE_COMPUTER_NAME = Environment.GetEnvironmentVariable("REMOTE_COMPUTER_NAME");
        readonly string USER_NAME = Environment.GetEnvironmentVariable("USER_NAME");
        readonly string PASSWORD = Environment.GetEnvironmentVariable("PASSWORD");

        string path = string.Empty;
        string PATH_TO_REMOTE_FILES = Environment.GetEnvironmentVariable("PATH_TO_REMOTE_FILES");
        //string path = $@"{Path.GetPathRoot(Environment.SystemDirectory)}\mounts\remote-files\";

        public FilesController()
        {
            path = string.Format($@"\\{REMOTE_COMPUTER_NAME}\{PATH_TO_REMOTE_FILES}");
        }

        public HttpResponseMessage Get()
        {

            string[] files;

            // List files in the directory
            //string[] files = Directory.GetFiles(path);

            using ((NetworkShareAccesser.Access(REMOTE_COMPUTER_NAME, USER_NAME, PASSWORD)))
            {
                files = Directory.GetFiles(path);
            }

            return Request.CreateResponse(HttpStatusCode.OK, files);
        }

        public HttpResponseMessage PostFormData()
        {

            //Fetch the File.
            HttpPostedFile postedFile = HttpContext.Current.Request.Files[0];

            try
            {
                // The easy way: same credentials, same domain
                //postedFile.SaveAs(path + postedFile.FileName);                

                // The hard way: different credentials, different domain
                //https://stackoverflow.com/questions/659013/accessing-a-shared-file-unc-from-a-remote-non-trusted-domain-with-credentials/684040#684040
                using ((NetworkShareAccesser.Access(REMOTE_COMPUTER_NAME, USER_NAME, PASSWORD)))
                {
                    postedFile.SaveAs($@"{path}\{postedFile.FileName}");
                }

                //return Request.CreateResponse(HttpStatusCode.OK);
                var response = Request.CreateResponse(HttpStatusCode.Moved);
                // Get the full URI

                response.Headers.Location = new Uri(HttpContext.Current.Request.Url.AbsoluteUri); //goes to GET /api/files
                return response;

            }
            catch (Exception e)
            {
                return Request.CreateErrorResponse(HttpStatusCode.InternalServerError, e);
            }
        }
    }
}