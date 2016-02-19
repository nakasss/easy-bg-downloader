using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using UnityEngine;


public class EasyBgDownloaderCtl : MonoBehaviour {
	//Show inspector values
	[SerializeField]
	private string requestURI = "";
	[SerializeField]
	private string destinationDirPath = "";
	public bool notificationEnabled = false;
	public bool cacheEnabled = false;

	//Inner Value
	private bool isDownloading = false;
	private static readonly string DEFAULT_CACHE_DIR = "ebd_tmp";

	//Property
	public string RequestURI {
		set { 
			this.requestURI = value;
			#if UNITY_ANDROID
			if (IsDownloadingNative()) {
				isDownloading = true;
			} else {
				isDownloading = false;
			}
			#endif
		}
		get { return this.requestURI; }
	}

	public string DestinationDirectoryPath {
		set { destinationDirPath = value; }
		get {
			if (string.IsNullOrEmpty(destinationDirPath)) {
                string dirPath;
				if (Application.platform == RuntimePlatform.Android) {
					dirPath = Application.temporaryCachePath + "/" + DEFAULT_CACHE_DIR;
				} else if (Application.platform == RuntimePlatform.IPhonePlayer) {
					dirPath = Application.temporaryCachePath + "/" + DEFAULT_CACHE_DIR;
				} else {
					dirPath = Application.streamingAssetsPath + "/" + DEFAULT_CACHE_DIR;
				}

				if (!Directory.Exists(dirPath)) {
					Directory.CreateDirectory (dirPath);
				}
                
                return dirPath;
			} else {
                return destinationDirPath;
            }
		}
	}

	//Event delegate values
	public delegate void StartDL (string requestURL);
	public delegate void CompleteDL (string requestURL, string filePath);
	public delegate void ErrorDL (string requestURL, string errorMessage, DOWNLOAD_ERROR errorCode = 0);
	public delegate void ClickAndroidDLStatusBar (string requestURL);
	public CompleteDL OnStart;
	public CompleteDL OnComplete;
	public ErrorDL OnError;
	public ClickAndroidDLStatusBar OnClickAndroidStatus;


	public enum DOWNLOAD_STATUS {
		IN_QUEUE = 0, //PENDING || RUNNING || PAUSED || FAILED
        PENDING = 10, 
		RUNNING = 20,
		PAUSED = 30,
		FAILED = 40
	}

	public enum DOWNLOAD_ERROR {
		NETWORK_ERROR = 1,
        INVALID_URL = 2,
        INVALID_DIR_PATH = 3,
        UNKNOWN_ERROR = 4
	}


	// Use this for initialization
	void Start () {
		initEBD ();
	}
	
	// Update is called once per frame
	void Update () {
		
	}

	void OnApplicationPause (bool pauseStatus) {
		if (pauseStatus) {
			pauseEBD ();
		} else {
			resumeEBD ();
		}
	}

	void OnDestroy () {
		terminateEBD ();
	}




	#if UNITY_ANDROID

	#region Android Functions
    /*
	 * Platform values
	 */
    private const string ANDROID_DOWNLOAD_MANAGER_PACKAGE_CLASS_NAME = "nl.scopic.downloadmanagerplugin.DownloadManagerPlugin";
	private AndroidJavaObject androidJavaObj = null;

	/*
	 * Life Cycle Control
	 */
    private void initEBD () {
		//Set Event Listener
		getJavaObj().Call("setCompleteReceiver");
		getJavaObj().Call("setStatusClickReceiver");

		getJavaObj ().Call ("startUpdateTask");
	}

	private void resumeEBD () {
		getJavaObj ().Call ("startUpdateTask");

		if (IsDownloadingNative()) {
			isDownloading = true;
		} else {
			isDownloading = false;
		}
	}

	private void pauseEBD () {
		getJavaObj ().Call ("stopUpdateTask");
	}
    
    private void terminateEBD () {
		//Unset Event Listerner
		getJavaObj().Call("unsetCompleteReceiver");
		getJavaObj().Call("unsetStatusClickReceiver");
	}

	/*
	 * Download Control
	 */
    public void Start (string requestURL) {
        //Check URL
        if (isInvalidURL(requestURL)) {
            return;
        }

        //Check Dir path
        if (isInvalidPath(DestinationDirectoryPath)) {
            return;
        }
	}

	public void Stop (string requestURL) {
	}

	public float GetProgress (string requestURL) {
	}

	public bool IsDownloading (string requestURL) {
	}

	/*
	 * Download Event
	 */
    private void onCompleteDL (string requestURL, string filePath) {
        

		if (OnComplete != null) {
			OnComplete (requestURL, filePath);
		}
	}

	private void onErrorDL (string requestURL, string errorMessage, DOWNLOAD_ERROR errorCode) {
		//TODO : convert error message to error code
		if (OnError != null) {
			OnError (requestURL, errorMessage, errorCode);
		}
	}
    
    private void onClickAndroidStatusBar (string requestURL) {
        
        if (OnClickAndroidStatus != null) {
            OnClickAndroidStatus(requestURL);
		}
    }
    

	/*
	 * Platform Specific Functions
	 */
     
    /*
	 * Plugin Interface
	 */
    private AndroidJavaObject getJavaObj() {
		if (androidJavaObj == null) {
			androidJavaObj = new AndroidJavaObject(ANDROID_DOWNLOAD_MANAGER_PACKAGE_CLASS_NAME, gameObject.name);
		}

		return androidJavaObj;
	}
    private void startInAndroid(string requestURL, string destPath, string naviTitle) {
        getJavaObj().Call("startDownload", requestURL, destPath, naviTitle);
    }
    private void stopInAndroid(string requestURL) {
        getJavaObj().Call("stopDownload", requestURL);
    }
    private float getProgressInAndroid(string requestURL) {
        getJavaObj().Call<float>("getProgress", requestURL);
    }
    private bool isDownloadingInAndroid(string requestURL) {
        getJavaObj().Call<bool> ("isDownloading", requestURI);
    }
    //Test
	public void CallTest () {
		getJavaObj().Call("callTest");
	}
	public void CallStaticTest () {
		getJavaObj().CallStatic("callStaticTest");
	}
    
    
    
     
	/*
	 * Android Functions
	 */

	// Start Download
	public void StartDownload (string statusTitle = null) {
		if (IsSetRequestURI() && IsSetDestURI()) {
			if (statusTitle == null) {
				statusTitle = Path.GetFileName (requestURI);
			}
			GetJavaObj().CallStatic<long>("startDownload", requestURI, destinationURI, statusTitle);
			isDownloading = true;
		}
	}

	//Stop Download
	public void StopDownload () {
		if (IsSetRequestURI()) {
			GetJavaObj ().CallStatic ("stopDownload", requestURI);
		}
	}

	//Get Progress
	public int GetProgress () {
		int progress = -1;
		if (IsSetRequestURI()) {
			long downloadID = GetDownloadID (requestURI);
			progress = GetJavaObj ().Call<int> ("getProgress", downloadID);
		}
		return progress;
	}

	// downloading or not by url
	private bool IsDownloadingNative () {
		if (IsSetRequestURI()) {
			return GetJavaObj ().CallStatic<bool> ("isDownloading", requestURI);	
		} else {
			return false;
		}
	}


	//Onlu Android function
	private long GetDownloadID (string url) {
		return GetJavaObj().CallStatic<long>("getDownloadID", url);
	}

	//Called When download Complete
	private void OnCompleteDownload (string id) {
		Debug.Log ("Finish Download ID : " + id);
		if (OnComplete != null) {
			OnComplete (id);
		}
		isDownloading = false;
	}

	//Called When download status clicked
	private void OnClickDownloadStatus (string message) {
		if (OnClickStatus != null) {
			OnClickStatus ();
		}
	}

	#endregion // END : Android Functions

	#elif UNITY_IPHONE // end : UNITY_ANDROID

	#region iOS Functions
	/*
	 * EBD Interface
	 */
	[DllImport("__Internal")]
	private static extern void EBDInterfaceInit (string productName, string gameObjName, bool cacheEnabled);
	[DllImport("__Internal")]
	private static extern void EBDInterfaceDestory ();
	[DllImport("__Internal")]
	private static extern void EBDInterfaceStartDownload (string requestedURL, string destinationPath);
	[DllImport("__Internal")]
	private static extern void EBDInterfaceStopDownload (string requestedURL);
	[DllImport("__Internal")]
	private static extern float EBDInterfaceGetProgress (string requestedURL);
	[DllImport("__Internal")]
	private static extern bool EBDInterfaceIsDownloading (string requestedURL);


	//test
	[DllImport("__Internal")]
	private static extern void EasyBgDownloaderTestVoid ();
	[DllImport("__Internal")]
	private static extern int EasyBgDownloaderTestReturnInt ();
	[DllImport("__Internal")]
	private static extern void EasyBgDownloaderTestValueInt (int i);


	private void InitPlugin () {
	//Set Event Listener
	}

	private void DestoryPlugin () {
	//Unset Event Listerner
	}

	private void ResumePlugin () {
	}

	private void PausePlugin () {
	}

	public void StartDownload () {

	}
	public void StopDownload () {

	}
	public int GetProgress () {
		int progress = -1;
		return progress;
	}
	private bool IsDownloadingNative () {
		return false;
	}
	//Called When download Complete
	private void OnCompleteDownload () {
		if (OnComplete != null) {
			OnComplete ("");
		}
		isDownloading = false;
	}

	//Test
	public void CallTest () {
		EasyBgDownloaderTestVoid ();
	}
	public void CallStaticTest () {
		EasyBgDownloaderTestValueInt (10);
	}
	public void CallUnitySendMessage (string message) {
		Debug.Log ("Get Message and Call it from Unity : " + message);
	}

	//Called When download Complete
	private void OnCompleteDownload (string url) {
		Debug.Log ("Finish Download URL : " + url);
		if (OnComplete != null) {
			OnComplete (url);
		}

		isDownloading = false;
	}

	#endregion // EDN : iOS Functions

	//#endif

	#else 

	#region /*** Editor Functions ***/
	/*
	 * Platform values
	 */
	private Dictionary<string, string> downloadTaskListInEditor;
	private string requestURLInEditor = "";
	private float currentProgressInEditor = 0.0f;

	/*
	 * Life Cycle Control
	 */
	private void initEBD () {
		downloadTaskListInEditor = new Dictionary<string, string>();
	}

	private void terminateEBD () {
	}

	private void pauseEBD () {
	}

	private void resumeEBD () {
	}

	/*
	 * Download Control
	 */
	public void Start (string requestURL) {
		if (isInQueue(requestURL)) {
			return;
		}
        
        //Check URL
        if (isInvalidURL(requestURL)) {
            return;
        }

        //Check Dir path
        if (isInvalidPath(DestinationDirectoryPath)) {
            return;
        }

		addTask (requestURL, DestinationDirectoryPath);
		StartCoroutine ("startInEditor", requestURL);
	}

	public void Stop (string requestURL) {
		stopInEditor (requestURL);
	}

	public float GetProgress (string requestURL) {
		if (requestURLInEditor != requestURL) {
			changeCurrentTask (requestURL);
		}

		return currentProgressInEditor;
	}

	public bool IsDownloading (string requestURL) {
		if (isInQueue (requestURL)) {
			return true;
		} else {
			return false;
		}
	}

	/*
	 * Download Event
	 */
	private void onCompleteDL (string requestURL, string filePath) {
		removeTask (requestURL);

		if (OnComplete != null) {
			OnComplete (requestURL, filePath);
		}
	}

	private void onErrorDL (string requestURL, string errorMessage, DOWNLOAD_ERROR errorCode) {
		//TODO : convert error message to error code
		if (OnError != null) {
			OnError (requestURL, errorMessage, errorCode);
		}
	}

	/*
	 * Platform Specific Functions
	 */
	private IEnumerator startInEditor (string requestURL) {
		WWW www = new WWW (requestURL);

		while (!www.isDone) {
			if (isInQueue (requestURL)) {
                Debug.Log("Progress : " + www.progress);
				if (requestURLInEditor == requestURL) {
                    currentProgressInEditor = www.progress;
                    if (currentProgressInEditor > 0.995) {
                        currentProgressInEditor = 1.0f;
                    }
				}
				yield return null;
			} else {
				//Queue Stopped
				break;
			}
		}
			
		if (isInQueue (requestURL)) {
			if (!string.IsNullOrEmpty (www.error)) {
				//Error occured
				onErrorDL(requestURL, www.error, DOWNLOAD_ERROR.NETWORK_ERROR);
			} else {
				if (requestURLInEditor == requestURL) {
					currentProgressInEditor = 1.0f;
				}
				saveFileAtPath (www, requestURL, downloadTaskListInEditor[requestURL]);
			}
		}
	}

	private void stopInEditor (string requestURL) {
		removeTask (requestURL);
	}

	private void saveFileAtPath (WWW data, string requestURL, string destPath) {
		if (!System.IO.Directory.Exists(destPath)) {
			Directory.CreateDirectory(destPath);
		}

		string fileName = Path.GetFileName(requestURL);
		System.IO.File.WriteAllBytes(destPath + "/" + fileName, data.bytes);

		//Donwload Complete
		onCompleteDL(requestURL, destPath);
	}

	private void changeCurrentTask (string requestURL) {
		requestURLInEditor = requestURL;
		currentProgressInEditor = 0.0f;
	}
		
	private bool isInQueue (string requestURL) {
		if (downloadTaskListInEditor.ContainsKey (requestURL)) {
			return true;
		} else {
			return false;
		}
	}

	private void addTask (string requestURL, string destPath) {
		if (downloadTaskListInEditor.ContainsKey (requestURL)) {
			if (downloadTaskListInEditor [requestURL] != destPath) {
				downloadTaskListInEditor [requestURL] = destPath;
			}
		} else {
			downloadTaskListInEditor.Add (requestURL, destPath);
		}
	}

	private void removeTask (string requestURL) {
		if (downloadTaskListInEditor.ContainsKey (requestURL)) {
			downloadTaskListInEditor.Remove (requestURL);
		}
	}

	#endregion // end : UNITY_EDITOR && UNITY_STANDALONE

	#endif


	#region /*** Common Functions ***/
	/*
	* Common Functions
	*/
	private bool isInvalidURL (string url) {
		//Has Scheme or not
		//file url or not
		Uri uriResult;
		if (Uri.TryCreate (url, UriKind.Absolute, out uriResult) && (uriResult.Scheme == Uri.UriSchemeHttp || uriResult.Scheme == Uri.UriSchemeHttps)) {
			return false;		
		} else {
			return true;
		}
	}

	private bool isInvalidPath (string destPath) {
		//No dir
		return !Directory.Exists(destPath);
	}

	#endregion
}
