using UnityEngine;
using System.Collections;

[RequireComponent(typeof(MobileUIView))]
public class MobileUIController : MonoBehaviour {
	[SerializeField]
	private MobileUIView mobileUIView;


	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}


	/*
	 * Start&StopButton
	 */
	public void OnClickCtlButton () {
		if (mobileUIView.IsStartEnabled()) {
			this.OnClickStartBtn ();
		} else {
			this.OnClickStopBtn ();
		}
	}

	private void OnClickStartBtn () {
		
		this.mobileUIView.EnableStopButton ();
	}

	private void OnClickStopBtn () {
		
		this.mobileUIView.EnableStartButton ();
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
}
