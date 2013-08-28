<%@ WebHandler Language="C#" Class="CSSHandler" %>
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Web;
using Microsoft.Ajax.Utilities;


/// <summary>
/// Summary description for CSSHandler
/// </summary>
public class CSSHandler : IHttpHandler
{

    public bool IsReusable
    {
        get { return true; }
    }

    public void ProcessRequest(HttpContext context)
    {
        var cssPaths = context.Request.QueryString["cssfiles"];
        if (!string.IsNullOrEmpty(cssPaths))
        {
            string[] cssFiles = cssPaths.Split(',');

            var files = new List<string>();
            var response = new StringBuilder();
            foreach (string cssFile in cssFiles)
            {
                if (!cssFile.EndsWith(".css", StringComparison.OrdinalIgnoreCase))
                {
                    //log custom exception
                    context.Response.StatusCode = 403;
                    return;
                }
                try
                {
                    string filePath = context.Server.MapPath(cssFile);
                    string css = File.ReadAllText(filePath);
                    response.Append(css);
                }
                catch (Exception ex)
                {
                    //log exception
                    context.Response.StatusCode = 500;
                    return;
                }
            }

            var minifier = new Minifier();
            var minCss = minifier.MinifyStyleSheet(response.ToString());
            context.Response.Write(minCss);

            string version = "1.0"; //your dynamic version number 
            context.Response.ContentType = "text/css";
            context.Response.AddFileDependencies(files.ToArray());
            HttpCachePolicy cache = context.Response.Cache;
            cache.SetCacheability(HttpCacheability.Public);
            cache.VaryByParams["cssfiles"] = true;
            cache.SetETag(version);
            cache.SetLastModifiedFromFileDependencies();
            cache.SetMaxAge(TimeSpan.FromDays(14));
            cache.SetRevalidation(HttpCacheRevalidation.AllCaches);
        }
    }
}
