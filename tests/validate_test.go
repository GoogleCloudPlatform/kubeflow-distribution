package tests

import (
	shutil "github.com/termie/go-shutil"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"testing"
)

// TestHydrate verifies we can properly hydrate the config
func TestHydrate(t *testing.T) {

	testDir, err := ioutil.TempDir("", "gcpBlueprintsTest-")

	if err != nil {
		t.Fatalf("Couldn't create temporary directory: %v", err)
	}

	currDir, err := os.Getwd()

	if err != nil {
		t.Fatalf("Couldn't get working directory %v", err)
	}

	kDir := path.Join(currDir, "..", "kubeflow")

	target := path.Join(testDir, "kubeflow")

	t.Logf("Using %v", target)
	shutil.CopyTree(kDir, target, nil)

	// Get the upstream packages
	cmd := exec.Command("make", "get-pkg")
	cmd.Dir = target

	out, err := cmd.CombinedOutput()
	t.Logf("Run %v :\n%v", cmd, string(out))

	if err != nil {
		t.Fatalf("%v failed; error %v", cmd, err)
	}

	setValues := func(vars map[string]string, subDir string) {
			for k, v := range vars {
				cmd := exec.Command("kpt", "cfg", "set", subDir, k, v)
				cmd.Dir = target
				out, err := cmd.CombinedOutput()

				t.Logf("Run %v:\n%v", cmd, string(out))

				if err != nil {
					t.Fatalf("%v failed; error %v", cmd, err)
				}
			}
	}
	instanceVars := map[string]string {
		"mgmt-ctxt": "mgmt-ctxt",
		"name": "kf-test",
		"gcloud.core.project": "kubeflow-ci-deployment",
		"location": "us-east1",
		"email": "user@gmail.com",
	}
	setValues(instanceVars, "instance")

	upstreamVars := map[string]string {
		"name": "kf-test",
		"gcloud.core.project": "kubeflow-ci-deployment",
		"gcloud.compute.zone": "us-east1-d",
		"location": "us-east1",
	}
	setValues(upstreamVars, "upstream/manifests/gcp")

	cmd = exec.Command("make", "hydrate")
	cmd.Dir = target
	out, err = cmd.CombinedOutput()

	t.Logf("Run %v:\n%v", cmd, string(out))

	if err != nil {
		t.Fatalf("%v failed; error %v", cmd, err)
	}
}
