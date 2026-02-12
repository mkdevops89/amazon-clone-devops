package main

import (
	"context"
	"fmt"
	"os"
	"path/filepath"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	fmt.Println("🚀 Ops Check: Verifying Cluster Health...")

	// Load Kubeconfig
	kubeconfig := filepath.Join(os.Getenv("HOME"), ".kube", "config")
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		fmt.Printf("❌ Error loading kubeconfig: %v\n", err)
		os.Exit(1)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		fmt.Printf("❌ Error creating clientset: %v\n", err)
		os.Exit(1)
	}

	// 1. Check Nodes
	checkNodes(clientset)

	// 2. Check Pods in default namespace
	checkPods(clientset)
}

func checkNodes(clientset *kubernetes.Clientset) {
	fmt.Println("\n🔎 Checking Nodes...")
	nodes, err := clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		fmt.Printf("❌ Failed to list nodes: %v\n", err)
		return
	}

	for _, node := range nodes.Items {
		status := "Unknown"
		for _, cond := range node.Status.Conditions {
			if cond.Type == "Ready" {
				status = string(cond.Status)
			}
			// Phase 8: Enhanced Monitoring (Pressure Checks)
			if cond.Status == "True" && (cond.Type == "MemoryPressure" || cond.Type == "DiskPressure" || cond.Type == "PIDPressure") {
				fmt.Printf("⚠️  WARNING: Node %s has %s!\n", node.Name, cond.Type)
			}
		}
		
		// Check Instance Type & Lifecycle (Spot vs On-Demand)
		instanceType := node.Labels["node.kubernetes.io/instance-type"]
		lifecycle := node.Labels["lifecycle"]
		if lifecycle == "" {
			lifecycle = "On-Demand"
		}

		if status == "True" {
			fmt.Printf("✅ Node %s (%s, %s) is Ready\n", node.Name, instanceType, lifecycle)
		} else {
			fmt.Printf("❌ Node %s is NOT Ready\n", node.Name)
		}
	}
}

func checkPods(clientset *kubernetes.Clientset) {
	fmt.Println("\n🔎 Checking Pods (default namespace)...")
	pods, err := clientset.CoreV1().Pods("default").List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		fmt.Printf("❌ Failed to list pods: %v\n", err)
		return
	}

	for _, pod := range pods.Items {
		if pod.Status.Phase == "Running" {
			fmt.Printf("✅ Pod %s is Running\n", pod.Name)
		} else if pod.Status.Phase == "Pending" {
			fmt.Printf("⚠️ Pod %s is Pending (Check events!)\n", pod.Name)
		} else {
			fmt.Printf("❌ Pod %s is %s\n", pod.Name, pod.Status.Phase)
		}
	}
}
