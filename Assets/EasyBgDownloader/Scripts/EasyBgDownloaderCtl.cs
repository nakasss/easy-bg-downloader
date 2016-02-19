using UnityEngine;
using System.Collections;
using System.IO;
using System.Runtime.InteropServices;


public class EasyBgDownloaderCtl : MonoBehaviour {
	//Show inspector values
	[SerializeField]
	private string requestURI = "";
	[SerializeField]
	private string destinationURI = "";
	[SerializeField]
	private string destinationDirectoryPath = "";
	public bool notificationEnabled = false;
	public bool cacheEnabled = false;

	//Inner Value
	private bool isDownloading = false;
	private static readonly string DEFAULT_CACHE_DIR = "ebd_tmp";

	//Property
	public string RequestURI {
		set { 
			this.requestURI = value;
			if (IsDownloadingNative()) {
				isDownloading = true;
			} else {
				isDownloading = false;
			}
		}
		get { return this.requestURI; }
	}

	public string DestinationURI {
		set { this.destinationURI = value; }
		get { return this.destinationURI; }
	}

	public string DestinationDirectoryPath {
		set { this.destinationDirectoryPath = value; }
		get {
			string dirPath = this.destinationDirectoryPath;
			if (string.IsNullOrEmpty (dirPath)) {
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
			}
			return dirPath;
		}
	}

	//Event delegate values
	public delegate void DownloadComplete (string url);
	public delegate void DownloadStatusClick ();
	public DownloadComplete OnComplete;
	public DownloadStatusClick OnClickStatus;



	// Use this for initialization
	void Start () {
		InitPlugin ();
	}
	
	// Update is called once per frame
	void Update () {
		
	}

	void OnApplicationPause (bool pauseStatus) {
		if (pauseStatus) {
			PausePlugin ();
		} else {
			ResumePlugin ();
		}
	}

	void OnDestroy () {
		DestoryPlugin ();
	}



	/*
	 * Common Functions
	 */
	private bool IsSetRequestURI () {
		if (string.IsNullOrEmpty (this.RequestURI)) {
			return false;
		} else {
			return true;
		}
	}

	private bool IsSetDestURI () {
		if (string.IsNullOrEmpty (this.DestinationURI)) {
			return false;
		} else {
			return true;
		}
	}

	public bool IsDownloading () {
		return isDownloading;
	}



	//#if !UNITY_EDITOR && !UNITY_STANDALONE

	#if UNITY_ANDROID
	/*
	 * Android Functions
	 */

	private const string ANDROID_DOWNLOAD_MANAGER_PACKAGE_CLASS_NAME = "nl.scopic.downloadmanagerplugin.DownloadManagerPlugin";
	private AndroidJavaObject androidPluginObj = null;

	private AndroidJavaObject GetJavaObj () {
		if (androidPluginObj == null) {
			androidPluginObj = new AndroidJavaObject(ANDROID_DOWNLOAD_MANAGER_PACKAGE_CLASS_NAME, gameObject.name);
		}

		return androidPluginObj;
	}

	private void InitPlugin () {
		//Set Event Listener
		GetJavaObj().Call("setCompleteReceiver");
		GetJavaObj().Call("setStatusClickReceiver");

		GetJavaObj ().Call ("startUpdateTask");
	}

	private void DestoryPlugin () {
		//Unset Event Listerner
		GetJavaObj().Call("unsetCompleteReceiver");
		GetJavaObj().Call("unsetStatusClickReceiver");
	}

	private void ResumePlugin () {
		GetJavaObj ().Call ("startUpdateTask");

		if (IsDownloadingNative()) {
			isDownloading = true;
		} else {
			isDownloading = false;
		}
	}

	private void PausePlugin () {
		GetJavaObj ().Call ("stopUpdateTask");
	}

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



	//Test
	public void CallTest () {
		GetJavaObj().Call("callTest");
	}
	public void CallStaticTest () {
		GetJavaObj().CallStatic("callStaticTest");
	}


	#elif UNITY_IPHONE // end : UNITY_ANDROID

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

	#endif // end : UNITY_IPHONE

	//#else // UNITY_EDITOR || UNITY_STANDALONE

	/*
	 * Editor functions
	 */

	//#endif // end : !UNITY_EDITOR && !UNITY_STANDALONE
}
