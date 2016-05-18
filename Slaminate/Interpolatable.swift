//
//  Interpolation.swift
//  Slaminate
//
//  Created by Kristian Trenskow on 06/02/16.
//  Copyright © 2016 Trenskow.io. All rights reserved.
//

import Foundation

protocol Interpolatable {
    var canInterpolate: Bool { get }
    func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable
    var objectValue: AnyObject { get }
}

extension Interpolatable {
    var canInterpolate: Bool {
        return true
    }
    var objectValue: AnyObject { return self as! AnyObject }
}

extension Bool: Interpolatable {
    func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable {
        return (position > 0.5 ? to : self)
    }
    var objectValue: AnyObject { return NSNumber(bool: self) }
}

extension Double: Interpolatable {
    func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable {
        return (to as! Double - self) * position + self
    }
    var objectValue: AnyObject { return NSNumber(double: self) }
}

extension Float: Interpolatable {
    func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable {
        return (to as! Float - self) * Float(position) + self
    }
    var objectValue: AnyObject { return NSNumber(float: self) }
}

extension CGFloat: Interpolatable {
    func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable {
        return (to as! CGFloat - self) * CGFloat(position) + self
    }
    var objectValue: AnyObject { return NSNumber(double: Double(self)) }
}

extension CGPoint: Interpolatable {
    func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable {
        return CGPoint(
            x: x.interpolate((to as! CGPoint).x, position) as! CGFloat,
            y: y.interpolate((to as! CGPoint).y, position) as! CGFloat
        )
    }
    var objectValue: AnyObject { return NSValue(CGPoint: self) }
}

extension CGSize: Interpolatable {
    func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable {
        return CGSize(
            width: width.interpolate((to as! CGSize).width, position) as! CGFloat,
            height: height.interpolate((to as! CGSize).height, position) as! CGFloat
        )
    }
    var objectValue: AnyObject { return NSValue(CGSize: self) }
}

extension CGRect: Interpolatable {
    func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable {
        return CGRect(
            origin: origin.interpolate((to as! CGRect).origin, position) as! CGPoint,
            size: size.interpolate((to as! CGRect).size, position) as! CGSize
        )
    }
    var objectValue: AnyObject { return NSValue(CGRect: self) }
}

private struct Quaternion: Equatable, Interpolatable {
    var x: CGFloat = 0.0
    var y: CGFloat = 0.0
    var z: CGFloat = 0.0
    var w: CGFloat = 0.0
    private func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable {
        return Quaternion(
            x: x.interpolate((to as! Quaternion).x, position) as! CGFloat,
            y: y.interpolate((to as! Quaternion).y, position) as! CGFloat,
            z: z.interpolate((to as! Quaternion).z, position) as! CGFloat,
            w: w.interpolate((to as! Quaternion).w, position) as! CGFloat
        )
    }
}

private func ==(lhs: Quaternion, rhs: Quaternion) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w
}

extension CATransform3D : Interpolatable {
    
    private init(a: [CGFloat]) {
        m11 = a[0];  m12 = a[1];  m13 = a[2];  m14 = a[3]
        m21 = a[4];  m22 = a[5];  m23 = a[6];  m24 = a[7]
        m31 = a[8];  m32 = a[9];  m33 = a[10]; m34 = a[11]
        m41 = a[12]; m42 = a[13]; m43 = a[14]; m44 = a[15]
    }
    
    private func toArray() -> [CGFloat] {
        return [
            m11, m12, m13, m14,
            m21, m22, m23, m24,
            m31, m32, m33, m34,
            m41, m42, m43, m44,
        ]
    }
    
    private func transpose(m: CATransform3D) -> CATransform3D {
        
        var mT = m.toArray()
        var rT = CATransform3D().toArray()
        
        for i: Int in 0...15 {
            
            let col = i % 4
            let row = i / 4
            let j = col * 4 + row
            
            rT[j] = mT[i]
            
        }
        
        return CATransform3D(a: rT)
        
    }
    
    private func matrixQuaternion(m: CATransform3D) -> Quaternion {
        
        var q = Quaternion()
        
        if (m.m11 + m.m22 + m.m33 > 0) {
            
            let t = m.m11 + m.m22 + m.m33 + 1.0
            let s = 0.5 / sqrt(t)
            
            q.w = s * t
            q.z = (m.m12 - m.m21) * s
            q.y = (m.m31 - m.m13) * s
            q.x = (m.m23 - m.m32) * s
            
        } else if (m.m11 > m.m22 && m.m11 > m.m33) {
            
            let t = m.m11 - m.m22 - m.m33 + 1.0
            let s = 0.5 / sqrt(t)
            
            q.x = s * t
            q.y = (m.m12 + m.m21) * s
            q.z = (m.m31 + m.m13) * s
            q.w = (m.m23 - m.m32) * s
            
        } else if (m.m22 > m.m33) {
            
            let t = -m.m11 + m.m22 - m.m33 + 1.0
            let s = 0.5 / sqrt(t)
            
            q.y = s * t
            q.x = (m.m12 + m.m21) * s
            q.w = (m.m31 - m.m13) * s
            q.z = (m.m23 + m.m32) * s
            
        } else {
            
            let t = -m.m11 - m.m22 + m.m33 + 1.0
            let s = 0.5 / sqrt(t)
            
            q.z = s * t
            q.w = (m.m12 - m.m21) * s
            q.x = (m.m31 + m.m13) * s
            q.y = (m.m23 + m.m32) * s
            
        }
        
        return q
        
    }
    
    private func quaternionMatrix(q: Quaternion) -> CATransform3D {
        
        var m = CATransform3D()
        
        m.m11 = 1.0 - 2.0 * pow(q.y, 2.0) - 2.0 * pow(q.z, 2.0)
        m.m12 = 2.0 * q.x * q.y + 2.0 * q.w * q.z
        m.m13 = 2.0 * q.x * q.z - 2.0 * q.w * q.y
        m.m14 = 0.0
        
        m.m21 = 2.0 * q.x * q.y - 2.0 * q.w * q.z
        m.m22 = 1.0 - 2.0 * pow(q.x, 2.0) - 2.0 * pow(q.z, 2.0)
        m.m23 = 2.0 * q.y * q.z + 2.0 * q.w * q.x
        m.m24 = 0.0
        
        m.m31 = 2.0 * q.x * q.z + 2.0 * q.w * q.y
        m.m32 = 2.0 * q.y * q.z - 2.0 * q.w * q.x
        m.m33 = 1.0 - 2.0 * pow(q.x, 2.0) - 2.0 * pow(q.y, 2.0)
        m.m34 = 0.0
        
        m.m41 = 0.0
        m.m42 = 0.0
        m.m43 = 0.0
        m.m44 = 1.0
        
        return m
        
    }
    
    private func interpolateQuaternion(a: Quaternion, b: Quaternion, position: Double) -> Quaternion {
        
        var q = Quaternion()
        
        let dp = Double(a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w)
        
        var theta = acos(dp)
        if (theta == 0.0) { return a }
        if (theta < 1.0) { theta *= -1.0 }
        
        let st = sin(theta)
        
        let sut = sin(position * theta)
        let sout = sin((1.0 - position) * theta)
        let coeff1 = CGFloat(sout / st)
        let coeff2 = CGFloat(sut / st)
        
        q.x = coeff1 * a.x + coeff2 * b.x
        q.y = coeff1 * a.y + coeff2 * b.y
        q.z = coeff1 * a.z + coeff2 * b.z
        q.w = coeff1 * a.w + coeff2 * b.w
        
        let qLen:CGFloat = sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w)
        q.x /= qLen
        q.y /= qLen
        q.z /= qLen
        q.w /= qLen
        
        return q
        
    }
    
    private init(tf: CATransform3D, s: Quaternion) {
        m11 = tf.m11 / s.x
        m12 = tf.m12 / s.x
        m13 = tf.m13 / s.x
        m14 = 0.0
        m21 = tf.m21 / s.y
        m22 = tf.m22 / s.y
        m23 = tf.m23 / s.y
        m24 = 0.0
        m31 = tf.m31 / s.z
        m32 = tf.m32 / s.z
        m33 = tf.m33 / s.z
        m34 = 0.0
        m41 = 0.0
        m42 = 0.0
        m43 = 0.0
        m44 = 1.0
    }
    
    func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable {
        
        var fromTf = self
        var toTf = to as! CATransform3D
        
        fromTf = transpose(fromTf)
        toTf = transpose(toTf)
        
        let from = Quaternion(x: fromTf.m14, y: fromTf.m24, z: fromTf.m34, w: 0.0)
        let to = Quaternion(x: toTf.m14, y: toTf.m24, z: toTf.m34, w: 0.0)
        let vT = from.interpolate(to, position) as! Quaternion
        
        let fromS = Quaternion(
            x: sqrt(pow(fromTf.m11, 2.0) + pow(fromTf.m12, 2.0) + pow(fromTf.m13, 2.0)),
            y: sqrt(pow(fromTf.m21, 2.0) + pow(fromTf.m22, 2.0) + pow(fromTf.m23, 2.0)),
            z: sqrt(pow(fromTf.m31, 2.0) + pow(fromTf.m32, 2.0) + pow(fromTf.m33, 2.0)),
            w: 0.0
        )
        let toS = Quaternion(
            x: sqrt(pow(toTf.m11, 2.0) + pow(toTf.m12, 2.0) + pow(toTf.m13, 2.0)),
            y: sqrt(pow(toTf.m21, 2.0) + pow(toTf.m22, 2.0) + pow(toTf.m23, 2.0)),
            z: sqrt(pow(toTf.m31, 2.0) + pow(toTf.m32, 2.0) + pow(toTf.m33, 2.0)),
            w: 0.0
        )
        
        let vS = fromS.interpolate(toS, position) as! Quaternion
        
        let fromRotation = CATransform3D(tf: fromTf, s: fromS)
        let toRotation = CATransform3D(tf: toTf, s: toS)
        
        var fromQuat = matrixQuaternion(fromRotation)
        var toQuat = matrixQuaternion(toRotation)
        
        let fromQuatLen: CGFloat = sqrt(fromQuat.x*fromQuat.x + fromQuat.y*fromQuat.y + fromQuat.z*fromQuat.z + fromQuat.w*fromQuat.w)
        fromQuat.x /= fromQuatLen
        fromQuat.y /= fromQuatLen
        fromQuat.z /= fromQuatLen
        fromQuat.w /= fromQuatLen
        let toQuatLen: CGFloat = sqrt(toQuat.x*toQuat.x + toQuat.y*toQuat.y + toQuat.z*toQuat.z + toQuat.w*toQuat.w)
        toQuat.x /= toQuatLen
        toQuat.y /= toQuatLen
        toQuat.z /= toQuatLen
        toQuat.w /= toQuatLen
        
        let valueQuat = interpolateQuaternion(fromQuat, b: toQuat, position: position)
        
        var valueTf = quaternionMatrix(valueQuat)
        
        valueTf.m11 *= vS.x
        valueTf.m12 *= vS.x
        valueTf.m13 *= vS.x
        
        valueTf.m21 *= vS.y
        valueTf.m22 *= vS.y
        valueTf.m23 *= vS.y
        
        valueTf.m31 *= vS.z
        valueTf.m32 *= vS.z
        valueTf.m33 *= vS.z
        
        valueTf.m14 = vT.x
        valueTf.m24 = vT.y
        valueTf.m34 = vT.z
        
        valueTf = transpose(valueTf)
        
        return valueTf
        
    }
    
    var objectValue: AnyObject { return NSValue(CATransform3D: self) }
    
}

extension UIColor: Interpolatable {
    
    private struct Components {
        var red:CGFloat = 0.0
        var blue:CGFloat = 0.0
        var green:CGFloat = 0.0
        var alpha:CGFloat = 0.0
    }
    
    private var components: Components {
        var components = Components()
        getRed(&components.red, green: &components.green, blue: &components.blue, alpha: &components.alpha)
        return components
    }
    
    func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable {
        let from = components
        let to = (to as! UIColor).components
        return self.dynamicType.init(
            red: from.red.interpolate(to.red, position) as! CGFloat,
            green: from.green.interpolate(to.green, position) as! CGFloat,
            blue: from.blue.interpolate(to.blue, position) as! CGFloat,
            alpha: from.alpha.interpolate(to.alpha, position) as! CGFloat
        )
    }
    
}

extension CGColorRef: Interpolatable {
    func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable {
        return (UIColor(CGColor: self).interpolate(UIColor(CGColor: to as! CGColorRef), position) as! UIColor).CGColor
    }
    var objectValue: AnyObject { return self }
}

extension NSValue: Interpolatable {
    
    private var typeEncoding: String {
        get {
            return String(CString: objCType, encoding: NSUTF8StringEncoding)!
            // Fix 32-bit
            .stringByReplacingOccurrencesOfString("NS", withString: "CG")
            .stringByReplacingOccurrencesOfString("ff", withString: "dd")
        }
    }
    
    private func value<T>(initialValue: T) -> T {
        var val = initialValue
        getValue(&val)
        return val
    }
    
    var canInterpolate: Bool {
        return [
            "f",
            "d",
            "{CGPoint=dd}",
            "{CGSize=dd}",
            "{CGRect={CGPoint=dd}{CGSize=dd}}",
            "{CATransform3D=dddddddddddddddd}"
        ].contains(typeEncoding)
    }
    
    func interpolate(to: Interpolatable, _ position: Double) -> Interpolatable {
        
        // If number - but not same type.
        if let to = to as? NSNumber, from = self as? NSNumber {
            if from.typeEncoding == "c" && to.typeEncoding == "c" {
                return NSNumber(bool: from.boolValue.interpolate(to.boolValue, position) as! Bool)
            }
            if from.typeEncoding != "d" || to.typeEncoding != "d" {
                return NSNumber(double: from.doubleValue.interpolate(to.doubleValue, position) as! Double)
            }
        }
        
        guard typeEncoding == (to as! NSValue).typeEncoding else {
            fatalError("Cannot interpolate NSValue instances of different type encoding.")
        }
        
        switch typeEncoding {
        case "f", "d":
            let val = value(Double()).interpolate((to as! NSValue).value(Double()), position)
            return NSNumber(double: val as! Double)
        case "{CGPoint=dd}",
             "{CGPoint=ff}",
             "{NSPoint=ff}",
             "{NSPoint=dd}":
            let val = value(CGPoint()).interpolate((to as! NSValue).value(CGPoint()), position)
            return NSValue(CGPoint: val as! CGPoint)
        case "{CGSize=dd}":
            let val = value(CGSize()).interpolate((to as! NSValue).value(CGSize()), position)
            return NSValue(CGSize: val as! CGSize)
        case "{CGRect={CGPoint=dd}{CGSize=dd}}":
            let val = value(CGRect()).interpolate((to as! NSValue).value(CGRect()), position)
            return NSValue(CGRect: val as! CGRect)
        case "{CATransform3D=dddddddddddddddd}":
            let val = value(CATransform3D()).interpolate((to as! NSValue).value(CATransform3D()), position)
            return NSValue(CATransform3D: val as! CATransform3D)
        default:
            fatalError("Interpolation does not support type encoding \(typeEncoding).")
            break
        }
        
    }
}
