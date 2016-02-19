using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class MobileUIView : MonoBehaviour {
	[SerializeField]
	private Animator mobileUIAnimator;


	// Use this for initialization
	void Start () {
		Debug.Log ("Font size : " + percentageLabel.fontSize);
	}
	
	// Update is called once per frame
	void Update () {
	
	}


	/*
	 * Main Page
	 */
	//[HeaderAttribute ("Footer Tab")]
	public void GoDownlaodPage () {
		mobileUIAnimator.SetBool ("IsOpenDownload", true);	
	}

	public void GoBrowsePage () {
		mobileUIAnimator.SetBool ("IsOpenDownload", false);
	}

	public bool IsOpenDownloadPage () {
		return mobileUIAnimator.GetBool ("IsOpenDownload");
	}
	// END : Main Page


	/*
	 * Downloading Panel
	 */
	[HeaderAttribute ("Downloading Panel")]
	[SerializeField]
	private Text percentageLabel;
	[SerializeField]
	private Image progressCircle;

	public void changePercentageLabel (float progress) {
		int percentage = (int)(progress * 100.0f);
		percentageLabel.text = percentage.ToString () + "%";
	}

	public void changeProgressCircle (float progress) {
		progressCircle.fillAmount = progress;
		this.changePercentageLabel (progress);
	}
	// END : Downloading Panel


	/*
	 * Start&StopButton
	 */
	[HeaderAttribute ("Start & Stop Button UI")]
	[SerializeField]
	private Text buttonLabel;

	public void EnableStartButton () {
		buttonLabel.text = "START";
		mobileUIAnimator.SetBool ("IsStartButton", true);
	}

	public void EnableStopButton () {
		buttonLabel.text = "STOP";
		mobileUIAnimator.SetBool ("IsStartButton", false);
	}

	public bool IsStartEnabled () {
		bool isStartBtn = mobileUIAnimator.GetBool ("IsStartButton");
		return isStartBtn;
	}
	// END : Start&StopButton

}
