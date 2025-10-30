from hms import Hms
from hms.model import Project

# from datetime import datetime

myProject = Project.open('HMS_Tirso_v3/HMS.hms')
myProject.computeRun('ERA5-Land_Current')
myProject.close()


print("Model simulated")
Hms.shutdownEngine()