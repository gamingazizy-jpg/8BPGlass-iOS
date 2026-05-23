#import "Prediction.h"

Prediction prediction;

extern "C" {

bool run_prediction() {
    return prediction.determineShotResult(false);
}

}
