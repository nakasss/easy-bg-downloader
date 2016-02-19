using UnityEngine;
using UnityEngine.UI;
using System;
using System.Collections;
using System.IO;


public class DownloadManagerTest : MonoBehaviour {
	private string footageDirName = "DownloadTest";
	[SerializeField]
	private InputField inputField;
	[SerializeField]
	private RawImage screen;
	[SerializeField]
	private Text progressText;
	[SerializeField]
	private DownloadManagerCtl dmctl;


	// Use this for initialization
	void Start () {
		Debug.Log("Persist Path : " + Application.persistentDataPath);
		//Debug.Log(Application.streamingAssetsPath);

		dmctl.OnComplete = OnComplete;
	}
	
	// Update is called once per frame
	void Update () {


		if (dmctl.IsDownloading()) {
			progressText.text = dmctl.GetProgress() + "%";
		}
	}


	public void OnClickStartDownload () {
		dmctl.CallTest();
		if (String.IsNullOrEmpty(inputField.text)) return;

		string requestedURI = inputField.text;
		string fileName = Path.GetFileName(inputField.text);
		#if UNITY_EDITOR
		string dirPath = Application.streamingAssetsPath + "/" + footageDirName;
		#elif UNITY_IPHONE || UNITY_ANDROID
		string dirPath = Application.persistentDataPath + "/" + footageDirName;
		#endif
		if (!Directory.Exists(dirPath)) {
			Directory.CreateDirectory(dirPath);
		}
		string destPath = dirPath + "/" + fileName;
		string destURI = "file://" + destPath;

		#if UNITY_ANDROID
		if (!File.Exists(destPath) && !dmctl.IsDownloading()) {
			dmctl.StartDownload();
		}
		#endif
	}


	public void OnClickStopDownload () {
		dmctl.CallStaticTest();

		#if UNITY_ANDROID
		if (dmctl.IsDownloading()) {
			dmctl.StopDownload();
		}
		#endif
	}


	public void OnClickFileCheck () {
		if (String.IsNullOrEmpty(inputField.text)) return;


		string requestedURI = inputField.text;
		string fileName = Path.GetFileName(inputField.text);
		#if UNITY_EDITOR
		string dirPath = Application.streamingAssetsPath + "/" + footageDirName;
		#elif UNITY_IPHONE || UNITY_ANDROID
		string dirPath = Application.persistentDataPath + "/" + footageDirName;
		#endif
		if (!Directory.Exists(dirPath)) {
			Directory.CreateDirectory(dirPath);
		}
		string destPath = dirPath + "/" + fileName;
		string destURI = "file://" + destPath;

		// Set URIs
		dmctl.RequestURI = requestedURI;
		dmctl.DestinationURI = destURI;

		// Status Check
		string status = "";
		if (File.Exists (destPath)) {
			status = "File exist : ";
		} else {
			status = "File NOT exist : ";
		}
		if (dmctl.IsDownloading()) {
			status += "Downloading.";
		} else {
			status += "NOT Downloading.";
		}
		progressText.text = status;

	}


	private void OnComplete(string id) {
		
	}
}
