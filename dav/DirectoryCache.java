/*
 * DirectoryCache.java - Caches remote directories to improve performance
 * Copyright (C) 2000 Slava Pestov
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with DirectoryCache.class program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

package dav;

import java.io.*;
import java.util.Enumeration;
import java.util.Hashtable;
import org.gjt.sp.jedit.io.*;
import org.gjt.sp.jedit.MiscUtilities;
import org.gjt.sp.jedit.jEdit;
import org.gjt.sp.util.Log;

public class DirectoryCache
{
	/**
	 * Returns the specified cached directory listing, or null if
	 * it is not in the cache.
	 * @param url The URL
	 * @since jEdit 2.6pre2
	 */
	public static VFS.DirectoryEntry[] getCachedDirectory(String url)
	{
		url = canon(url);
		ObjectInputStream in = null;
		String path = null;

		synchronized(lock)
		{
			path = (String)urlToCacheFileHash.get(url);
			if(path != null)
			{
				try
				{
					in = new ObjectInputStream(
						new BufferedInputStream(
						new FileInputStream(path)));
				return (VFS.DirectoryEntry[])in.readObject();
				}
				catch(Throwable e)
				{
					Log.log(Log.ERROR,DirectoryCache.class,e);
					return null;
				}
				finally
				{
					if(in != null)
					{
						try
						{
							in.close();
						}
						catch(Throwable e)
						{
						}
					}
				}

			}
			else
				return null;
		}
	}

	/**
	 * Caches the specified directory listing.
	 * @param url The URL
	 * @param directory The directory listing
	 * @since jEdit 2.6pre2
	 */
	public static void setCachedDirectory(String url, VFS.DirectoryEntry[] directory)
	{
		if(cacheDirectory == null)
			return;

		url = canon(url);

		synchronized(lock)
		{
			// filename generation algorithm is really simple...
			tmpFileCount++;
			long time = System.currentTimeMillis();
			String path = MiscUtilities.constructPath(cacheDirectory,
				"cache-" + tmpFileCount + "-" + time + ".tmp");

			ObjectOutputStream out = null;
			try
			{
				out = new ObjectOutputStream(
					new BufferedOutputStream(
					new FileOutputStream(path)));
				out.writeObject(directory);

				Log.log(Log.DEBUG,DirectoryCache.class,"Cached "
					+ url + " to " + path);

				urlToCacheFileHash.put(url,path);
			}
			catch(Throwable e)
			{
				Log.log(Log.ERROR,DirectoryCache.class,e);
			}
			finally
			{
				if(out != null)
				{
					try
					{
						out.close();
					}
					catch(Throwable e)
					{
					}
				}
			}
		}
	}

	/**
	 * Removes the cached listing of the specified directory.
	 * @param url The URL
	 * @since jEdit 2.6pre5
	 */
	public static void clearCachedDirectory(String url)
	{
		url = canon(url);

		synchronized(lock)
		{
			Enumeration enum = urlToCacheFileHash.keys();
			while(enum.hasMoreElements())
			{
				String path = (String)enum.nextElement();
				if(path.startsWith(url))
				{
					String cacheFile = (String)urlToCacheFileHash.remove(path);
					Log.log(Log.DEBUG,DirectoryCache.class,"Deleting " + cacheFile);
					new File(cacheFile).delete();
				}
			}
		}
	}

	/**
	 * Removes all cached directory listings.
	 * @since jEdit 2.6pre5
	 */
	public static void clearAllCachedDirectories()
	{
		synchronized(lock)
		{
			Enumeration files = urlToCacheFileHash.elements();
			while(files.hasMoreElements())
			{
				String path = (String)files.nextElement();
				Log.log(Log.DEBUG,DirectoryCache.class,"Deleting " + path);
				new File(path).delete();
			}
			urlToCacheFileHash.clear();
		}
	}

	// private members
	private static Object lock = new Object();
	private static int tmpFileCount;
	private static Hashtable urlToCacheFileHash;
	private static String cacheDirectory;

	private DirectoryCache() {}

	/* This method exists so that foo/ and foo will both be cached
	 * as the same URL. When the VFSPath class arrives, will get rid
	 * of this kludge */
	private static String canon(String url)
	{
		if(url.length() != 0 && (url.endsWith("/")
			|| url.endsWith(File.separator)))
			return url.substring(0,url.length() - 1);
		else
			return url;
	}

	static
	{
		urlToCacheFileHash = new Hashtable();

		String settingsDirectory = jEdit.getSettingsDirectory();
		if(settingsDirectory == null)
		{
			Log.log(Log.WARNING,DirectoryCache.class,"-nosettings "
				+ "command line switch specified; remote directories");
			Log.log(Log.WARNING,DirectoryCache.class,"will not be cached.");
		}
		else
		{
			cacheDirectory = MiscUtilities.constructPath(settingsDirectory,
				"cache");
			new File(cacheDirectory).mkdirs();
		}
	}
}
