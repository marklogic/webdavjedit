/*
 * TODO:
 *  Get locks working properly
 *	- Issues with lock ownership, locks cannot be removed for some reason
 *		FIXED - was using signature that called for owner/time instead of path/time
 *	- Only have one entry per given file in lockedFiles vector
 *	- unlockFile should remove that file from lockedFiles
 *	- unlockAllFiles should repeatedly call unlockFile on the front element of lockedFiles
 *		until lockedFiles is empty
 *
 *  Add functionality
 *	- Add ability to lock/unlock individual files
 *		- Requires GUIs for browsing remote directory
 *	- Add ability to set file properties
 *		- Will require GUI similar to locking GUI
 *
 *	NOTE: Could possibly do both of these in the same function, since locks are properties too
 *
 *  Code cleanup
 *	- Check if resolveSymLink method is really necessary
 *	- Check if normalize method is really necessary
 *	- Check if newFileName (Previously used in _saveComplete) is really necessary
 *	- Remove unnecessary import statements
 */

package dav;

import gnu.regexp.*;
import java.awt.Component;
import java.io.*;
import java.net.*;
import java.util.*;

import javax.swing.*;
import java.lang.*;
import java.io.FileInputStream;
import java.io.File;
import java.io.IOException;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.FileNotFoundException;
import java.util.Date;
import java.util.Stack;
import java.util.Vector;
import java.util.Hashtable;
import java.util.Enumeration;
import java.util.StringTokenizer;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.net.URL;
import java.net.MalformedURLException;

import org.gjt.sp.jedit.io.*;
import org.gjt.sp.jedit.search.RESearchMatcher;
import org.gjt.sp.jedit.*;
import org.gjt.sp.util.Log;
import org.apache.util.HttpURL;
import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpStatus;
import org.apache.commons.httpclient.HttpException;
import org.apache.webdav.lib.WebdavResource;
import org.apache.webdav.lib.methods.*;
import org.apache.webdav.lib.Lock;
import org.apache.webdav.lib.properties.LockDiscoveryProperty;
import org.apache.commons.httpclient.*;
import org.apache.commons.httpclient.methods.GetMethod;
import org.apache.commons.httpclient.methods.PutMethod;


public class DavVFS extends VFS
{
	public static final String PROTOCOL = "http";

	// same as File VFS permissions key!
	public static final String PERMISSIONS_PROPERTY = "FileVFS__perms";

	// The default Local Working Directory
	public static String WORKING_DIRECTORY = "WebDAV";
	
	private static String newFileName = "";

	public DavVFS()
	{
		super("dav");
	}

	/*specifyWorkingDirectory
	 *  Creates a directory in jEdit's install directory where all WebDAV file transfers will be saved to
	 */
	public static void specifyWorkingDirectory()
	{
		String inputValue = JOptionPane.showInputDialog("Working directory will be created within jEdit's install directory");
		if (inputValue != null){
			WORKING_DIRECTORY = inputValue;
			new File(WORKING_DIRECTORY).mkdir();
		}
	}
	
	
	public int getCapabilities()
	{
		return READ_CAP | WRITE_CAP | BROWSE_CAP;
	}


	public String showBrowseDialog(Object[] session, Component comp)
	{
		String browsePath;
		ConnectionManager.ConnectionInfo newSession =
			(ConnectionManager.ConnectionInfo)createVFSSession(
			null,comp);

		if(newSession == null)
			return null;

		if(session != null)
			session[0] = newSession;

		// need trailing / to detect that the path is in fact a
		// directory
		browsePath = constructPath(newSession.getHost(), newSession.getPath());
		if ( !browsePath.endsWith("/") )
			browsePath = browsePath + "/";

		return browsePath;
	}


	public String getFileName(String path)
	{
		DavAddress address = new DavAddress(path);
		if(address.path.equals("/") || address.path.length() == 1)
		{
			address.path = "";
			return address.toString();
		}
		else
			return super.getFileName(address.path);
	}


	public String getParentOfPath(String path)
	{
		DavAddress address = new DavAddress(path);
		address.path = super.getParentOfPath(address.path);
		return address.toString();
	}


	public String constructPath(String parent, String path)
	{
		DavAddress address;
		if(path.startsWith("~"))
			path = "/" + path;

		if(path.startsWith("/"))
		{
			address = new DavAddress(parent);
			address.path = address.path + path;
			return address.toString();
		}
		else if(parent.endsWith("/"))
			return parent + path;
		else
			return parent + '/' + path;
	}



	/*reloadDirectory
	 * clears the cached directory, forcing it to reload next time it is browsed
	 */
	public void reloadDirectory(String path)
	{
		DirectoryCache.clearCachedDirectory(path);
	}


	public Object createVFSSession(String path, Component comp)
	{
		try
		{
			return ConnectionManager.getConnectionInfo(comp,
				path == null ? null : new DavAddress(path));
		}
		catch(IllegalArgumentException ia)
		{
			// DavAddress can throw this
			return null;
		}
	}


	/*_listDirectory
	 * Returns a vector contaning the information of a given path
	 * For us, calls listBasic and parses the information accordingly
	 */
	public VFS.DirectoryEntry[] _listDirectory(Object _session, String stringUrl,
		Component comp) throws IOException
	{
		VFS.DirectoryEntry[] directory = DirectoryCache.getCachedDirectory(stringUrl);
		if(directory != null)
			return directory;

		HttpURL httpURL = null;
		WebdavResource webdavResource = null;
		Vector list = null;
		Vector directoryVector = null;
		DavDirectoryEntry entry = null;
		String[] format = null;
		DavAddress addy = null;
		ConnectionManager.ConnectionInfo info = null;

		try{

		addy = new DavAddress(stringUrl);
	
	    //info = ConnectionManager.getConnectionInfo(comp,addy);
		webdavResource = ConnectionManager.getResource(stringUrl);
		
		list = webdavResource.listBasic();
		//webdavResource.close();
		directoryVector = new Vector();

		for(int i = 0; i < list.size(); i++)
		{
			format = (String[])list.elementAt(i);

			//File name
			String name = format[0];
			
			//File size
			long length = Long.parseLong( format[1].trim() );
			
			//File type
			int type = (format[2].equals("COLLECTION")) ?
				VFS.DirectoryEntry.DIRECTORY : VFS.DirectoryEntry.FILE;

			// prepend directory to create full path
			String path = constructPath( stringUrl, name );
			String deletePath = path;
			boolean hidden = false;
			entry = new DavDirectoryEntry( name, path, deletePath, type, length, hidden);
			directoryVector.addElement( entry );
		}
		directory = new DavDirectoryEntry[directoryVector.size()];
		directoryVector.copyInto(directory);
		DirectoryCache.setCachedDirectory(stringUrl,directory);

		} catch (Throwable we) {
                        if (webdavResource.getStatusCode() ==
				HttpStatus.SC_METHOD_NOT_ALLOWED) {
					JOptionPane.showMessageDialog(comp,
						"Unable to connect3 to server, "+
						"please make sure that the host, " +
						"username and password are correct.\n" +
						"If problem persists, contact Server "+
						"Administrator for further assistance.");
				return null;
			}
			JOptionPane.showMessageDialog(comp, "_listDirectory: Warning: " + we.getMessage());
		}
		return(directory);
	}



	/*TODO:
	 * Do we really need this?  LINK may or may not be supported in DAV systems
	 */
	static class DavDirectoryEntry extends VFS.DirectoryEntry
	{
		public static final int LINK = 10;

		public DavDirectoryEntry(String name, String path, String deletePath,
			int type, long length, boolean hidden)
		{
			super(name,path,deletePath,type,length,hidden);
		}
	}


	/*_createInputStream
	 * Returns an inputstream which jEdit uses to load a file into a buffer
	 * For us, we do not have direct access to the InputStream used to GET files
	 * First GET the file to the local working directory
	 * Lock the file if possible
	 *  - if successful, add file name to vector containing locked files
	 * Use a fileInputStream on the file in the local working directory
	 *
	 * TODO:
	 *  Lock file before GET'ing
	 */
	public InputStream _createInputStream(Object _session, String path,
		boolean ignoreErrors, Component comp) throws IOException
	{
	    FileInputStream in = null;
	    try {
		ConnectionManager.ConnectionInfo connection
			= (ConnectionManager.ConnectionInfo)_session;
		
		WebdavResource resource
			= ConnectionManager.getResource(path);

		
		//InputStream in = null;
		File newFile;

		
		DavAddress address = new DavAddress(path);
		String src = address.path;
		String dest = src;
		int index = dest.lastIndexOf('/');
		try
		{
			if (index != -1)
				dest = dest.substring(index+1);

			//Prevent the downloading of .marks files
			if( !dest.endsWith(".marks"))
			{
				//Start LockManager for this file

				
				newFile = new File(WORKING_DIRECTORY, dest);
				resource.getMethod(src, newFile);
				in = new FileInputStream(newFile);
				LockManager lm = new LockManager( path, connection.getUser(), connection.getPassword() );
				lm.start();
				//in = resource.getMethodData();
				//resource.close();
			}

		}catch (HttpException we) {
			//JOptionPane.showMessageDialog(comp, "createInputStream() warning:\n" + we.getMessage());
			//Log.log(Log.ERROR, DavVFS.class, "createInputStream(): " + resource.getStatusMessage());
			try {
					newFile = new File(WORKING_DIRECTORY, dest);
					resource.getMethod(src, newFile);
					in = new FileInputStream(newFile);
			}catch (HttpException e) {
					JOptionPane.showMessageDialog(comp, "createInputStream() warning:\n" + e.getMessage());
			}catch (IOException ioe) {
		}
		}catch (IOException io) {
		}catch (Throwable e) {
		}
	    } catch (Throwable t) {
	    }
	    return in;
	}



	/*_createOutputStream
	 * Returns an OutputStream that jEdit uses to save the buffer into a file
	 * For us, we do not have direct access to the OutputStream used for PUT commands
	 * Hack it so that we save the file to the local working directory using a FileVFS
	 * Actually call PUT later
	 *
	 * TODO:
	 *  Make sure we no longer need newFileName, now that _saveComplete has the path name passed in
	 */
	public OutputStream _createOutputStream(Object _session, String path,
		Component comp) throws IOException
	{
	    //		JOptionPane.showMessageDialog(null, "_createOutputStream(" +
	    //					      "path="+path);

		FileVFS vfs = new FileVFS();
		int index = path.lastIndexOf('/');
		if (index != -1)
			path = path.substring(index+1);
			
		//Cheap hack
		newFileName = path;
		
		return vfs._createOutputStream( _session, WORKING_DIRECTORY + "/" + path, comp );
	}


	/*_saveComplete
	 * Runs any cleanup necessary after saving a file
	 * For us, this means we can finally call PUT
	 * New in 4.1, path is passed in, saving us a bit of hassle in determining file name, etc.
	 *
	 * TODO:
	 *  Check to see if we NEED to have a lock on a file in order to PUT it
	 */
	public void _saveComplete(Object _session, Buffer buffer, String path, Component comp)
		throws IOException
	{
	    //		JOptionPane.showMessageDialog(null, "_savComplete(" +
	    //					      "path="+path);
		ConnectionManager.ConnectionInfo connection
			= (ConnectionManager.ConnectionInfo)_session;

		WebdavResource resource
			= ConnectionManager.getResource(path);
			
		//If resource is null, we're putting up a new file to the server
		if ( resource == null ){
		    //		    JOptionPane.showMessageDialog(null, "_savComplete(" +
		    //						  "resource was null path="+path);
			resource = ConnectionManager.getResource(getParentOfPath(path));
			//			path = path.substring(path.lastIndexOf('/')+1);
			//			JOptionPane.showMessageDialog(null, "_savComplete(" +
			//			      "resource was null new path="+path);			
			DavAddress add = new DavAddress(path);
			path = add.path;
			//JOptionPane.showMessageDialog(null, "_savComplete(" +
			//			  "resource was null new path="+path);			
		}
		
		//		JOptionPane.showMessageDialog(comp, "_saveComplete() putting: " + path);
		HttpURL url = resource.getHttpURL();
		File newFile;
		try
		{
		    //JOptionPane.showMessageDialog(null, "_savComplete(" +
		    //			  "path="+path);
		    //JOptionPane.showMessageDialog(null, "_savComplete(" +
		    //				  "filename="+newFileName);


			Log.log(Log.DEBUG, DavVFS.class, "Filename = " + path + "\nUser = " + url.getUserName() + "\nPassword = " + url.getPassword());
			newFile = new File(WORKING_DIRECTORY, newFileName);
			if(!resource.putMethod(path, newFile))
				JOptionPane.showMessageDialog(comp, "PUT request failed: " + resource.getStatusMessage());
			//resource.close();
			//Have to clear the cache of the full path name in order to see saved file
			DirectoryCache.clearCachedDirectory(getParentOfPath(path));
			
		}catch (HttpException we) {
			JOptionPane.showMessageDialog(comp, "_saveComplete() warning: " + we.getMessage());
			Log.log(Log.ERROR, DavVFS.class, "Error in save: " + resource.getStatusMessage());
		}catch (Throwable e) {
			JOptionPane.showMessageDialog(comp, "_saveComplete() error: " + e.getMessage());
		}
	}

	
	/*resolveSymlink
	 * This is a method to resolve symbolic links in a file system
	 * Not sure if WebDAV supports links, so we may not need it
	 */
	private void resolveSymlink(Object _session,
		String dir, DavDirectoryEntry entry, Component comp)
		throws IOException
	{
 		String name = entry.name;
		int index = name.indexOf(" -> ");
		String link = null;
		DavDirectoryEntry linkDirEntry = null;

		if(index == -1)
		{
			//non-standard link representation. Treat as a file
			//Some Mac and NT based servers do not use the "->" for symlinks
			entry.path = constructPath(dir,name);
			entry.type = VFS.DirectoryEntry.FILE;
			Log.log(Log.NOTICE,this,"File '"
				+ name
				+ "' is listed as a link, but will be treated"
				+ " as a file because no '->' was found.");
			return;
		}
		link = name.substring(index + " -> ".length());
		link = constructPath(dir,link);
		linkDirEntry = (DavDirectoryEntry)
			_getDirectoryEntry(_session,link,comp);
		if(linkDirEntry == null)
			entry.type = VFS.DirectoryEntry.FILE;
		else
		{
			entry.type = linkDirEntry.type;
		}

		entry.name = name.substring(0,index);
		entry.path = link;
		entry.deletePath = constructPath(dir,entry.name);
	}


	/*normalize
	 * Returns a string that is the normalized version of the given path
	 * Brought over from FTP (or was it Slide?)
	 * Seems to be good stuff
	 *
	 * TODO:
	 *  Determine if we need this
	 */
	public static String normalize(String path) {
		if (path == null)
			return null;

		String normalized = path;

		// Normalize the slashes and add leading slash if necessary
		if (normalized.indexOf('\\') >= 0)
			normalized = normalized.replace('\\', '/');
		if (!normalized.startsWith("/"))
			normalized = "/" + normalized;

		// Resolve occurrences of "/./" in the normalized path
		while (true) {
			int index = normalized.indexOf("/./");
			if (index < 0)
				break;
			normalized = normalized.substring(0, index) +
			normalized.substring(index + 2);
		}

		// Resolve occurrences of "/../" in the normalized path
		while (true) {
			int index = normalized.indexOf("/../");
			if (index < 0)
				break;
			if (index == 0)
				return ("/");  // The only left path is the root.
			int index2 = normalized.lastIndexOf('/', index - 1);
			normalized = normalized.substring(0, index2) +
			normalized.substring(index + 3);
		}

		// Resolve occurrences of "//" in the normalized path
		while (true) {
			int index = normalized.indexOf("//");
			if (index < 0)
				break;
			normalized = normalized.substring(0, index) +
			normalized.substring(index + 1);
		}

		// Return the normalized path that we have completed
		return (normalized);
	}

	/*deleteDir
	 * Recursively deletes the given directory and all sub-directories and files contained within
	 * Returns true if all files and sub-directories were deleted properly
	 */
	public static boolean deleteDir(File dir){
		 if (dir.isDirectory()) {
			 String[] children = dir.list();
			 for (int i=0; i<children.length; i++) {
				 boolean success = deleteDir(new File(dir, children[i]));
				 if (!success) {
					 return false;
				 }
			 }
		 }
      
		  // The directory is now empty, return true
		  return dir.delete();
	 }
}
