import * as mtoken from "./mtoken/structs";
import {StructClassLoader} from "../_framework/loader";

export function registerClasses(loader: StructClassLoader) { loader.register(mtoken.AdminCap);
loader.register(mtoken.VestingManager);
 }
