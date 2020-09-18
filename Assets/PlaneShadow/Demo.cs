using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Demo : MonoBehaviour
{
    public Animator Animator;

    public void PlayWalkAnim()
    {
        Animator.SetTrigger("Walk");
    }
    public void StopWalkAnim()
    {
        Animator.SetTrigger("WalkFinish");
    }

}
