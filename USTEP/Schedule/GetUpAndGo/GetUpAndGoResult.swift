//
// This source file is part of the CS342 2023 Utah Team Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//
// swiftlint:disable type_contents_order

import ModelsR4
import ResearchKit.Private
import ResearchKitOnFHIR


public class GetUpAndGoStepResult: ORKTextQuestionResult {
    public var score: Int? {
        didSet {
            if let score = score {
                self.answer = String(score) as NSString
                self.textAnswer = String(score)
            } else {
                self.answer = nil
                self.textAnswer = ""
            }
        }
    }

    var fhirAnswer: ModelsR4.QuestionnaireResponseItemAnswer? {
        guard let score = self.score else {
            return nil
        }
        
        var coding = ModelsR4.Coding(code: FHIRPrimitive<FHIRString>(FHIRString(String(score))))
        switch score {
        case 2:
            coding.display = FHIRPrimitive<FHIRString>("1-10 Seconds")
            break
        case 1:
            coding.display = FHIRPrimitive<FHIRString>("11-20 Seconds")
            break
        case 0:
            coding.display = FHIRPrimitive<FHIRString>(">21 Seconds")
            break
        default:
            coding.display = FHIRPrimitive<FHIRString>("Other")
            break
        }
        
        var answer = ModelsR4.QuestionnaireResponseItemAnswer()
        answer.value = .coding(coding)
        return answer
    }
    
    enum Keys: String {
        case score
    }

    override public init(identifier: String) {
        super.init(identifier: identifier)
    }

    override public func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(score, forKey: Keys.score.rawValue)
    }

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        score = aDecoder.decodeObject(forKey: Keys.score.rawValue) as? Int
    }

    public class func supportsSecureCoding() -> Bool {
        true
    }

    override public func isEqual(_ object: Any?) -> Bool {
        let isParentSame = super.isEqual(object)

        if let castObject = object as? GetUpAndGoStepResult {
            return (isParentSame &&
                    (score == castObject.score))
        }
        return true
    }

    override public func copy(with zone: NSZone? = nil) -> Any {
        if let result = super.copy(with: zone) as? GetUpAndGoStepResult {
            result.score = score
            return result
        } else {
            return super.copy(with: zone)
        }
    }
}
