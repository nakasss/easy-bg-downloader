using UnityEngine;
using System.Collections;

[RequireComponent(typeof(MobileUIView))]
public class MobileUIController : MonoBehaviour {
	[SerializeField]
	private EasyBgDownloaderCtl ebdCtl;
	[SerializeField]
	private MobileUIView mobileUIView;
	[SerializeField]
	private BrowseView browseView;
    
    private string currentDownloadURL = "";


	// Use this for initialization
	void Start () {
		ebdCtl.OnComplete = OnCompleteDownload;
	}
	
	// Update is called once per frame
	void Update () {
       //update download progress
	   if (!string.IsNullOrEmpty(currentDownloadURL) && ebdCtl.IsDownloading(currentDownloadURL)) {
           mobileUIView.ChangeHeaderLabel("DOWNLOADING");
           mobileUIView.ChangeDownloadingFileNameWithPath(currentDownloadURL);
           mobileUIView.ChangeProgress(ebdCtl.GetProgress(currentDownloadURL));
       }
	}


	/*
	 * Downloading Panel
	 */
	public void OnProgressChanged () {
		mobileUIView.ChangePercentageLabel (mobileUIView.progressManager.value);
	}
	// END : Downloading Panel

	/*
	 * Start&StopButton
	 */
	public void OnClickCtlButton () {
        string inputText = mobileUIView.GetInputText();
        if (string.IsNullOrEmpty(inputText)) {
            return;
        }
        
		if (mobileUIView.IsStartEnabled()) {
			OnClickStartBtn (inputText);
		} else {
			OnClickStopBtn (inputText);
		}
	}

	private void OnClickStartBtn (string inputURL) {
        currentDownloadURL = inputURL;
        ebdCtl.Start(inputURL);
		mobileUIView.EnableStopButton ();
	}

	private void OnClickStopBtn (string inputURL) {
        currentDownloadURL = "";
        ebdCtl.Stop(inputURL);
        mobileUIView.ChangeHeaderLabel("DOWNLOAD CANCELD");
        mobileUIView.ChangeDownloadingFileName("No file downloading");
        mobileUIView.ChangeProgress(0.0f);
		mobileUIView.EnableStartButton ();
	}
	// END : Start&StopButton

	/*
	 * Footer Tab
	 */
	public void OnClickTabDownload () {
		if (!mobileUIView.IsOpenDownloadPage()) {
			mobileUIView.GoDownlaodPage ();
		}
	}
	public void OnClickTabBrowse () {
		if (mobileUIView.IsOpenDownloadPage()) {
			mobileUIView.GoBrowsePage ();
		}
	}
	// END : Footer Tab

	/*
	 * EBD Event
	 */
	public void OnCompleteDownload (string requestURL, string destPath) {
		browseView.RefreshFileList ();
		mobileUIView.EnableStartButton ();
        mobileUIView.ChangeDownloadingFileName("No file downloading");
        mobileUIView.ChangeHeaderLabel("FINISH DOWNLOAD");
	}
    
    public void OnErrorDownload (string requestURL, string errorMessage) {
        mobileUIView.ChangeHeaderLabel(errorMessage);
    }
}
